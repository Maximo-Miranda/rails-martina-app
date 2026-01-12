# frozen_string_literal: true

module Gemini
  class CitationExtractor
    MIN_CONFIDENCE_THRESHOLD = 0.3

    class << self
      # Extracts citations from Gemini grounding metadata
      #
      # @param grounding_metadata [Hash] the groundingMetadata from Gemini response
      # @param stores [Array<GeminiFileSearchStore>] the stores to scope document lookup
      # @return [Array<Hash>] array of citation hashes with document info and pages
      def extract(grounding_metadata:, stores:)
        return [] if grounding_metadata.blank?

        chunks = grounding_metadata["groundingChunks"] || []
        supports = grounding_metadata["groundingSupports"] || []

        return [] if chunks.empty?

        chunk_pages, documents_by_display_name = parse_chunks(chunks, stores)

        infer_missing_pages!(chunk_pages)

        citations_map = collect_citations(chunk_pages, documents_by_display_name, supports)

        citations_map.values.map { |c| finalize_citation(c) }
      end

      private

      def parse_chunks(chunks, stores)
        display_names = []

        chunk_pages = chunks.map do |chunk|
          parse_single_chunk(chunk, display_names)
        end

        unique_names = display_names.compact.uniq
        documents_by_display_name = load_documents(unique_names, stores)

        [ chunk_pages, documents_by_display_name ]
      end

      def parse_single_chunk(chunk, display_names)
        if (context = chunk["retrievedContext"])
          title = context["title"]
          display_names << title if title.present?

          text = context["text"] || ""
          pages = text.scan(/---\s*PAGE\s+(\d+)\s*---/i).flatten.map(&:to_i).uniq

          { display_name: title, pages: pages, text: text }
        elsif (web_data = chunk["web"])
          { display_name: nil, pages: [], web_title: web_data["title"] }
        else
          { display_name: nil, pages: [] }
        end
      end

      def load_documents(display_names, stores)
        return {} if display_names.empty? || stores.empty?

        docs = ActsAsTenant.without_tenant do
          Document.kept
                  .where(gemini_file_search_store: stores)
                  .where(display_name: display_names)
                  .includes(file_attachment: :blob)
                  .to_a
        end

        docs.index_by(&:display_name)
      end

      def infer_missing_pages!(chunk_pages)
        chunk_pages.each_with_index do |chunk_info, idx|
          next unless chunk_info[:pages].empty? && chunk_info[:display_name]

          inferred_page = find_adjacent_page(chunk_pages, idx, chunk_info[:display_name])
          chunk_info[:pages] = [ inferred_page ].compact if inferred_page
        end
      end

      def find_adjacent_page(chunk_pages, current_idx, display_name)
        # Look backwards first
        (0...current_idx).reverse_each do |i|
          chunk = chunk_pages[i]
          return chunk[:pages].max if chunk[:display_name] == display_name && chunk[:pages].any?
        end

        # Then look forwards
        ((current_idx + 1)...chunk_pages.size).each do |i|
          chunk = chunk_pages[i]
          return chunk[:pages].min if chunk[:display_name] == display_name && chunk[:pages].any?
        end

        nil
      end

      def collect_citations(chunk_pages, documents_by_display_name, supports)
        citations_map = {}

        if supports.any?
          process_supports(chunk_pages, supports, documents_by_display_name, citations_map)
        else
          chunk_pages.each do |chunk_info|
            add_citation(citations_map, chunk_info, documents_by_display_name, nil)
          end
        end

        citations_map
      end

      def process_supports(chunk_pages, supports, documents_by_display_name, citations_map)
        supports.each do |support|
          indices = support["groundingChunkIndices"] || []
          scores = support["confidenceScores"]

          indices.each_with_index do |idx, i|
            score = scores.present? ? (scores[i] || 0.0) : nil
            should_include = score.nil? || score >= MIN_CONFIDENCE_THRESHOLD

            if should_include
              chunk_info = chunk_pages[idx]
              add_citation(citations_map, chunk_info, documents_by_display_name, score) if chunk_info
            end
          end
        end
      end

      def add_citation(citations_map, chunk_info, documents_by_display_name, confidence_score)
        display_name = chunk_info[:display_name]
        return unless display_name

        document = documents_by_display_name[display_name]
        return unless document

        key = document.id
        if citations_map[key]
          citations_map[key][:pages].concat(chunk_info[:pages])
          citations_map[key][:snippets] << extract_snippet(chunk_info[:text]) if chunk_info[:text].present?
          update_confidence(citations_map[key], confidence_score)
        else
          citations_map[key] = {
            document: document,
            pages: chunk_info[:pages].dup,
            snippets: chunk_info[:text].present? ? [ extract_snippet(chunk_info[:text]) ].compact : [],
            confidence_score: confidence_score,
          }
        end
      end

      def extract_snippet(text, max_length: 200)
        return nil if text.blank?

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
          text_snippet: citation[:snippets]&.first,
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
