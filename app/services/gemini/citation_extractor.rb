# frozen_string_literal: true

module Gemini
  class CitationExtractor
    MIN_CONFIDENCE_THRESHOLD = 0.7

    class << self
      # Extracts citations from Gemini grounding metadata
      #
      # @param grounding_metadata [Hash] the groundingMetadata from Gemini response
      # @param project [Project] the project to scope document lookup
      # @return [Array<Hash>] array of citation hashes with document info and pages
      def extract(grounding_metadata:, project:)
        return [] if grounding_metadata.blank?

        chunks = grounding_metadata["groundingChunks"] || []
        supports = grounding_metadata["groundingSupports"] || []

        return [] if chunks.empty?

        documents_by_filename = load_documents(chunks, project)
        build_citations(chunks, supports, documents_by_filename)
      end

      private

      def load_documents(chunks, project)
        filenames = chunks.filter_map do |chunk|
          chunk.dig("retrievedContext", "title")
        end.uniq

        return {} if filenames.empty?

        Document.kept
                .where(project: project)
                .where(display_name: filenames)
                .includes(file_attachment: :blob)
                .index_by(&:display_name)
      end

      def build_citations(chunks, supports, documents_by_filename)
        citations_map = {}

        if supports.present?
          build_from_supports(chunks, supports, documents_by_filename, citations_map)
        else
          build_from_chunks(chunks, documents_by_filename, citations_map)
        end

        citations_map.values.map { |c| finalize_citation(c) }
      end

      def build_from_supports(chunks, supports, documents_by_filename, citations_map)
        supports.each do |support|
          indices = support["groundingChunkIndices"] || []
          scores = support["confidenceScores"] || []

          indices.each_with_index do |chunk_idx, i|
            score = scores[i] || 0.0
            next if score < MIN_CONFIDENCE_THRESHOLD

            chunk = chunks[chunk_idx]
            next unless chunk

            add_chunk_to_citations(chunk, score, documents_by_filename, citations_map)
          end
        end
      end

      def build_from_chunks(chunks, documents_by_filename, citations_map)
        chunks.each do |chunk|
          add_chunk_to_citations(chunk, nil, documents_by_filename, citations_map)
        end
      end

      def add_chunk_to_citations(chunk, confidence_score, documents_by_filename, citations_map)
        context = chunk["retrievedContext"]
        return unless context

        filename = context["title"]
        return if filename.blank?

        document = documents_by_filename[filename]
        return unless document

        pages = extract_pages_from_text(context["text"])
        text_snippet = extract_snippet(context["text"])

        key = document.id
        if citations_map[key]
          citations_map[key][:pages].concat(pages)
          citations_map[key][:snippets] << text_snippet if text_snippet.present?
          update_confidence(citations_map[key], confidence_score)
        else
          citations_map[key] = {
            document: document,
            pages: pages,
            snippets: text_snippet.present? ? [ text_snippet ] : [],
            confidence_score: confidence_score,
          }
        end
      end

      def extract_pages_from_text(text)
        return [] if text.blank?

        text.scan(/---\s*PAGE\s+(\d+)\s*---/i).flatten.map(&:to_i).uniq
      end

      def extract_snippet(text, max_length: 200)
        return nil if text.blank?

        # Remove page markers and clean up
        cleaned = text.gsub(/---\s*PAGE\s+\d+\s*---/i, "").squish
        return nil if cleaned.blank?

        cleaned.truncate(max_length, separator: " ", omission: "…")
      end

      def update_confidence(citation, new_score)
        return unless new_score

        current = citation[:confidence_score]
        citation[:confidence_score] = [ current, new_score ].compact.max
      end

      def finalize_citation(citation)
        document = citation[:document]
        pages = citation[:pages].uniq.sort

        {
          document_id: document.id,
          display_name: document.display_name,
          file_url: build_file_url(document, pages),
          pages: pages,
          text_snippet: citation[:snippets].first,
          confidence_score: citation[:confidence_score],
        }
      end

      def build_file_url(document, pages)
        return nil unless document.file.attached?

        base_url = Rails.application.routes.url_helpers.rails_blob_url(
          document.file,
          host: default_url_host
        )

        pages.present? ? "#{base_url}#page=#{pages.first}" : base_url
      end

      def default_url_host
        Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3100"
      end
    end
  end
end
