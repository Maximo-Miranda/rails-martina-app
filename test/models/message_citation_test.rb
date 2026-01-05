# frozen_string_literal: true

require "test_helper"

class MessageCitationTest < ActiveSupport::TestCase
  setup do
    @message = messages(:model_response_one)
    @store = gemini_file_search_stores(:active_store)
    @user = users(:confirmed_user)

    # Create a document for testing citations
    @document = create_test_document
  end

  def create_test_document
    document = Document.new(
      display_name: "Ley 820 de 2003.pdf",
      content_type: "application/pdf",
      size_bytes: 1024,
      file_hash: SecureRandom.hex(32),
      gemini_file_search_store: @store,
      uploaded_by: @user,
      project: @store.project,
      status: :active
    )

    document.file.attach(
      io: StringIO.new("PDF content"),
      filename: "Ley 820 de 2003.pdf",
      content_type: "application/pdf"
    )

    document.save!
    document
  end

  # === VALIDATIONS ===

  test "valid citation" do
    citation = MessageCitation.new(
      message: @message,
      document: @document,
      pages: [ 1, 2, 3 ],
      text_snippet: "El contrato de arrendamiento de vivienda urbana...",
      confidence_score: 0.95
    )

    assert citation.valid?
  end

  test "requires message" do
    citation = MessageCitation.new(document: @document)

    assert citation.invalid?
    assert_includes citation.errors.attribute_names, :message
  end

  test "requires document" do
    citation = MessageCitation.new(message: @message)

    assert citation.invalid?
    assert_includes citation.errors.attribute_names, :document
  end

  test "unique message and document combination" do
    MessageCitation.create!(
      message: @message,
      document: @document,
      pages: [ 1 ]
    )

    duplicate = MessageCitation.new(
      message: @message,
      document: @document,
      pages: [ 2 ]
    )

    assert duplicate.invalid?
    assert_includes duplicate.errors.attribute_names, :message_id
  end

  test "confidence_score must be between 0 and 1" do
    invalid_high = MessageCitation.new(
      message: @message,
      document: @document,
      confidence_score: 1.5
    )

    invalid_low = MessageCitation.new(
      message: @message,
      document: @document,
      confidence_score: -0.1
    )

    assert invalid_high.invalid?
    assert invalid_low.invalid?
  end

  # === SCOPES ===

  test "high_confidence scope" do
    high = MessageCitation.create!(
      message: @message,
      document: @document,
      confidence_score: 0.9
    )

    low_doc = create_test_document
    low_doc.update!(file_hash: SecureRandom.hex(32))

    low = MessageCitation.create!(
      message: @message,
      document: low_doc,
      confidence_score: 0.5
    )

    high_confidence = MessageCitation.high_confidence

    assert high_confidence.include?(high)
    assert_not high_confidence.include?(low)
  end

  test "with_pages scope" do
    with_pages = MessageCitation.create!(
      message: @message,
      document: @document,
      pages: [ 1, 2 ]
    )

    no_pages_doc = create_test_document
    no_pages_doc.update!(file_hash: SecureRandom.hex(32))

    without_pages = MessageCitation.create!(
      message: @message,
      document: no_pages_doc,
      pages: []
    )

    citations_with_pages = MessageCitation.with_pages

    assert citations_with_pages.include?(with_pages)
    assert_not citations_with_pages.include?(without_pages)
  end

  # === INSTANCE METHODS ===

  test "document_file_url returns URL with page anchor" do
    citation = MessageCitation.create!(
      message: @message,
      document: @document,
      pages: [ 5, 10 ]
    )

    url = citation.document_file_url

    assert_not_nil url
    assert_match(/#page=5$/, url)
  end

  test "document_file_url returns URL without anchor when no pages" do
    citation = MessageCitation.create!(
      message: @message,
      document: @document,
      pages: []
    )

    url = citation.document_file_url

    assert_not_nil url
    assert_no_match(/#page=/, url)
  end

  test "pages_formatted returns formatted string for single page" do
    citation = MessageCitation.new(pages: [ 5 ])

    assert_equal I18n.t("chats.citations.single_page", page: 5), citation.pages_formatted
  end

  test "pages_formatted returns formatted string for multiple pages" do
    citation = MessageCitation.new(pages: [ 1, 5, 10 ])

    assert_equal I18n.t("chats.citations.multiple_pages", pages: "1, 5, 10"), citation.pages_formatted
  end

  test "pages_formatted returns nil for empty pages" do
    citation = MessageCitation.new(pages: [])

    assert_nil citation.pages_formatted
  end
end
