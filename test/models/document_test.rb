# frozen_string_literal: true

require "test_helper"
require "digest"

class DocumentTest < ActiveSupport::TestCase
  setup do
    @store = gemini_file_search_stores(:active_store)
    @global_store = gemini_file_search_stores(:global_store)
    @user = users(:confirmed_user)
  end

  def build_blob(content: "hi", filename: "test.txt", content_type: "text/plain", byte_size: nil)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    )
    blob.update!(byte_size: byte_size) if byte_size
    blob
  end

  def build_document(attributes = {})
    blob = attributes.delete(:blob)
    skip_file = attributes.delete(:skip_file)

    document = Document.new({
      gemini_file_search_store: @store,
      uploaded_by: @user,
      project: @store.project,
    }.merge(attributes))

    document.file.attach(blob || build_blob) unless skip_file
    document
  end

  test "valid document" do
    document = build_document

    assert document.valid?
    assert_equal "pending", document.status
  end

  test "requires file and related metadata" do
    document = build_document(skip_file: true, display_name: nil, content_type: nil, size_bytes: nil, file_hash: nil)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :file
    assert_includes document.errors.attribute_names, :display_name
    assert_includes document.errors.attribute_names, :content_type
    assert_includes document.errors.attribute_names, :size_bytes
    assert_includes document.errors.attribute_names, :file_hash
  end

  test "rejects unsupported content type" do
    document = build_document(blob: build_blob(content_type: "image/png", filename: "image.png"))

    assert document.invalid?
    assert_includes document.errors.attribute_names, :content_type
  end

  test "rejects oversized file" do
    blob = build_blob(byte_size: Document::MAX_FILE_SIZE + 1)
    document = build_document(blob: blob)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :size_bytes
  end

  test "requires unique remote_id" do
    existing = build_document(file_hash: "hash-1", remote_id: "remote-123")
    existing.save!

    duplicate = build_document(file_hash: "hash-2", remote_id: "remote-123")

    assert duplicate.invalid?
    assert_includes duplicate.errors.attribute_names, :remote_id
  end

  test "file_hash must be unique per store while kept" do
    first = build_document(file_hash: "dup-hash")
    first.save!

    second = build_document(file_hash: "dup-hash")
    assert second.invalid?
    assert_includes second.errors.attribute_names, :file_hash

    first.discard
    third = build_document(file_hash: "dup-hash")

    assert third.valid?
  end

  test "compute_file_hash fills SHA256 on create" do
    document = build_document(display_name: nil, file_hash: nil)
    expected_hash = Digest::SHA256.hexdigest(document.file.download)

    assert document.valid?
    assert_equal expected_hash, document.file_hash
  end

  test "set_file_metadata populates content_type size and display_name" do
    document = build_document(display_name: nil, content_type: nil, size_bytes: nil, file_hash: nil)

    assert document.valid?
    assert_equal document.file.blob.content_type, document.content_type
    assert_equal document.file.blob.byte_size, document.size_bytes
    assert_equal document.file.blob.filename.to_s, document.display_name
  end

  test "store capacity validation blocks oversized uploads" do
    @store.update!(size_bytes: Document::MAX_STORE_SIZE - 5.megabytes)
    blob = build_blob(byte_size: 10.megabytes)
    document = build_document(blob: blob, file_hash: "cap-test")

    assert document.invalid?
    errors = document.errors.details[:base].map { |error| error[:error] }
    assert_includes errors, :store_capacity_exceeded
  end

  test "store capacity allows documents within remaining space" do
    @store.update!(size_bytes: 5.megabytes)
    blob = build_blob(byte_size: 10.megabytes)
    document = build_document(blob: blob, file_hash: "cap-ok")

    assert document.valid?
  end

  test "duplicate_exists? detects kept duplicates" do
    existing = build_document(file_hash: "dup-check")
    existing.save!

    candidate = build_document(file_hash: "dup-check")

    assert_predicate candidate, :duplicate_exists?

    candidate.file_hash = nil
    refute_predicate candidate, :duplicate_exists?
  end

  test "global? and synced? helpers" do
    global_document = build_document(gemini_file_search_store: @global_store, project: nil, file_hash: "global-hash")
    assert global_document.global?

    synced_document = build_document(file_hash: "synced-hash", remote_id: "remote-1", status: :active)
    assert synced_document.synced?

    synced_document.status = :pending
    refute synced_document.synced?
  end

  test "store_available_bytes reflects remaining capacity" do
    document = build_document

    expected = Document::MAX_STORE_SIZE - @store.size_bytes
    assert_equal expected, document.store_available_bytes
  end

  test "scopes work as expected" do
    global_document = build_document(gemini_file_search_store: @global_store, project: nil, file_hash: "global")
    global_document.save!

    project_document = build_document(file_hash: "project")
    project_document.save!

    synced_document = build_document(file_hash: "synced", remote_id: "rid-123", status: :active)
    synced_document.save!

    assert_includes Document.global, global_document
    assert_includes Document.for_project(@store.project), project_document
    assert_includes Document.for_store(@store), project_document
    assert_includes Document.synced, synced_document
    refute_includes Document.synced, project_document
  end

  test "extension_for_content_type returns extension" do
    assert_equal ".txt", Document.extension_for_content_type("text/plain")
  end

  test "ransackable attributes and associations" do
    assert_equal %w[id display_name content_type status created_at], Document.ransackable_attributes
    assert_equal %w[project gemini_file_search_store uploaded_by], Document.ransackable_associations
  end
end
