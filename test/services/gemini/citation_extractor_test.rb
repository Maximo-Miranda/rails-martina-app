# frozen_string_literal: true

require "test_helper"

# Unit tests for CitationExtractor - tests the extraction logic without real API calls
class Gemini::CitationExtractorTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @store = gemini_file_search_stores(:active_store)
    @user = users(:confirmed_user)
  end

  test "extracts citations from grounding metadata with documents" do
    doc1 = create_test_document("Ley 1564 de 2012 - CGP", "hash001")
    doc2 = create_test_document("Decreto 1069 de 2015", "hash002")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "uri" => "some/uri/1",
            "title" => doc1.display_name,
            "text" => "El artículo 82 establece los requisitos ---PAGE 15---",
          },
        },
        {
          "retrievedContext" => {
            "uri" => "some/uri/2",
            "title" => doc2.display_name,
            "text" => "El decreto reglamentario dispone ---PAGE 42---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Reference text 1" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.85 ],
        },
        {
          "segment" => { "text" => "Reference text 2" },
          "groundingChunkIndices" => [ 1 ],
          "confidenceScores" => [ 0.72 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 2, citations.length

    citation1 = citations.find { |c| c[:document_id] == doc1.id }
    assert_not_nil citation1
    assert_equal doc1.display_name, citation1[:display_name]
    assert_includes citation1[:pages], 15
    assert_equal 0.85, citation1[:confidence_score]

    citation2 = citations.find { |c| c[:document_id] == doc2.id }
    assert_not_nil citation2
    assert_includes citation2[:pages], 42
    assert_equal 0.72, citation2[:confidence_score]
  end

  test "consolidates multiple references to same document with highest confidence" do
    doc = create_test_document("Ley 1564 CGP", "hash_multi")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "uri" => "uri/1",
            "title" => doc.display_name,
            "text" => "Artículo 82 ---PAGE 15--- y luego ---PAGE 16---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "First reference" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.75 ],
        },
        {
          "segment" => { "text" => "Second reference" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.92 ],
        },
        {
          "segment" => { "text" => "Third reference" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.88 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    citation = citations.first

    assert_equal doc.id, citation[:document_id]
    # Highest confidence should be used
    assert_equal 0.92, citation[:confidence_score]
  end

  test "filters out low confidence citations below threshold" do
    doc1 = create_test_document("High Confidence Doc", "hash_high")
    doc2 = create_test_document("Low Confidence Doc", "hash_low")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc1.display_name,
            "text" => "Alta confianza ---PAGE 10---",
          },
        },
        {
          "retrievedContext" => {
            "title" => doc2.display_name,
            "text" => "Baja confianza ---PAGE 20---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "High confidence" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.85 ],
        },
        {
          "segment" => { "text" => "Low confidence" },
          "groundingChunkIndices" => [ 1 ],
          "confidenceScores" => [ 0.05 ], # Below 0.1 threshold
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    assert_equal doc1.id, citations.first[:document_id]
  end

  test "returns empty array for nil grounding metadata" do
    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: nil,
      project: @project
    )
    assert_empty citations
  end

  test "returns empty array for empty grounding metadata" do
    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: {},
      project: @project
    )
    assert_empty citations
  end

  test "returns empty array when groundingChunks is missing" do
    grounding_metadata = {
      "groundingSupports" => [],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )
    assert_empty citations
  end

  test "handles missing document gracefully" do
    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => "Non-existent Document",
            "text" => "Some text ---PAGE 5---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Reference" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.90 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_empty citations
  end

  test "extracts multiple pages from text with PAGE markers" do
    doc = create_test_document("Page Format Test", "hash_pages")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc.display_name,
            "text" => "Content ---PAGE 5--- more content ---PAGE 10--- end ---PAGE 15---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Multiple pages" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.85 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    pages = citations.first[:pages]
    assert_includes pages, 5
    assert_includes pages, 10
    assert_includes pages, 15
  end

  test "removes duplicate pages and sorts them in ascending order" do
    doc = create_test_document("Duplicate Pages Test", "hash_dup")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc.display_name,
            "text" => "---PAGE 20--- ---PAGE 5--- ---PAGE 15--- ---PAGE 5---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Reference" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.85 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    assert_equal [ 5, 15, 20 ], citations.first[:pages]
  end

  test "extracts and cleans text snippets removing PAGE markers" do
    doc = create_test_document("Snippet Test Doc", "hash_snippet")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc.display_name,
            "text" => "El artículo 82 del CGP establece los requisitos ---PAGE 15--- formales de la demanda",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Full support text" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.90 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    snippet = citations.first[:text_snippet]
    assert_not_nil snippet
    assert_includes snippet, "artículo 82"
    refute_includes snippet, "---PAGE 15---"
  end

  test "extracts citations from chunks when no groundingSupports present" do
    doc = create_test_document("No Supports Doc", "hash_nosup")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc.display_name,
            "text" => "Some content ---PAGE 10---",
          },
        },
      ],
      # No groundingSupports
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    assert_equal doc.id, citations.first[:document_id]
    assert_nil citations.first[:confidence_score]
  end

  test "uses highest confidence when same chunk referenced multiple times" do
    doc = create_test_document("Multi Confidence Doc", "hash_conf")

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc.display_name,
            "text" => "First chunk ---PAGE 1---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Low confidence ref" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.75 ],
        },
        {
          "segment" => { "text" => "High confidence ref" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.95 ],
        },
        {
          "segment" => { "text" => "Medium confidence ref" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.85 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    assert_equal 1, citations.length
    assert_equal 0.95, citations.first[:confidence_score]
  end

  test "only returns citations for documents in the specified project" do
    other_project = projects(:pending_project)
    other_store = gemini_file_search_stores(:pending_store)

    # Document in current project
    doc_current = create_test_document("Current Project Doc", "hash_current")

    # Document in other project - create with attached file
    doc_other = Document.new(
      project: other_project,
      gemini_file_search_store: other_store,
      uploaded_by: @user,
      display_name: "Other Project Doc",
      content_type: "application/pdf",
      size_bytes: 1000,
      file_hash: "hash_other",
      status: :active,
      remote_id: "files/hash_other"
    )
    doc_other.file.attach(
      io: StringIO.new("Other project content"),
      filename: "hash_other.txt",
      content_type: "text/plain"
    )
    doc_other.save!

    grounding_metadata = {
      "groundingChunks" => [
        {
          "retrievedContext" => {
            "title" => doc_current.display_name,
            "text" => "Current project content ---PAGE 1---",
          },
        },
        {
          "retrievedContext" => {
            "title" => doc_other.display_name,
            "text" => "Other project content ---PAGE 2---",
          },
        },
      ],
      "groundingSupports" => [
        {
          "segment" => { "text" => "Ref 1" },
          "groundingChunkIndices" => [ 0 ],
          "confidenceScores" => [ 0.90 ],
        },
        {
          "segment" => { "text" => "Ref 2" },
          "groundingChunkIndices" => [ 1 ],
          "confidenceScores" => [ 0.90 ],
        },
      ],
    }

    citations = Gemini::CitationExtractor.extract(
      grounding_metadata: grounding_metadata,
      project: @project
    )

    # Should only return the document from current project
    assert_equal 1, citations.length
    assert_equal doc_current.id, citations.first[:document_id]
  end

  private

  def create_test_document(display_name, file_hash)
    doc = Document.new(
      project: @project,
      gemini_file_search_store: @store,
      uploaded_by: @user,
      display_name: display_name,
      status: :active,
      remote_id: "files/#{file_hash}"
    )

    # Attach a dummy file to satisfy validation
    doc.file.attach(
      io: StringIO.new("Test content for #{display_name}"),
      filename: "#{file_hash}.txt",
      content_type: "text/plain"
    )

    doc.file_hash = file_hash # Override computed hash with our test hash
    doc.save!
    doc
  end
end
