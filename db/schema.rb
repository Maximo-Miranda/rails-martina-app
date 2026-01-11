# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_05_013541) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "gemini_file_search_store_id", null: false
    t.integer "messages_count", default: 0, null: false
    t.bigint "project_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_chats_on_deleted_at"
    t.index ["gemini_file_search_store_id"], name: "index_chats_on_gemini_file_search_store_id"
    t.index ["project_id", "user_id"], name: "index_chats_on_project_and_user"
    t.index ["project_id"], name: "index_chats_on_project_id"
    t.index ["status"], name: "index_chats_on_status"
    t.index ["user_id", "created_at"], name: "index_chats_on_user_and_created_at"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "documents", force: :cascade do |t|
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "custom_metadata", default: {}
    t.datetime "deleted_at"
    t.string "display_name", null: false
    t.text "error_message"
    t.string "file_hash", null: false
    t.string "gemini_document_path"
    t.bigint "gemini_file_search_store_id", null: false
    t.bigint "project_id"
    t.string "remote_id"
    t.bigint "size_bytes", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.index ["deleted_at"], name: "index_documents_on_deleted_at"
    t.index ["file_hash", "gemini_file_search_store_id"], name: "idx_documents_hash_store_unique", unique: true, where: "(deleted_at IS NULL)"
    t.index ["gemini_file_search_store_id"], name: "index_documents_on_gemini_file_search_store_id"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["remote_id"], name: "index_documents_on_remote_id", unique: true, where: "(remote_id IS NOT NULL)"
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
  end

  create_table "event_store_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.binary "data", null: false
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.integer "position"
    t.string "stream", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "gemini_file_search_stores", force: :cascade do |t|
    t.integer "active_documents_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "display_name", null: false
    t.text "error_message"
    t.string "gemini_store_name"
    t.jsonb "metadata", default: {}
    t.bigint "project_id"
    t.bigint "size_bytes", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_gemini_file_search_stores_on_deleted_at"
    t.index ["gemini_store_name"], name: "index_gemini_file_search_stores_on_gemini_store_name", unique: true
    t.index ["project_id", "display_name"], name: "index_gemini_file_search_stores_on_project_id_and_display_name", unique: true
    t.index ["project_id"], name: "index_gemini_file_search_stores_on_project_id"
  end

  create_table "message_citations", force: :cascade do |t|
    t.decimal "confidence_score", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.bigint "message_id", null: false
    t.integer "pages", default: [], array: true
    t.text "text_snippet"
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_message_citations_on_document_id"
    t.index ["message_id", "document_id"], name: "index_message_citations_uniqueness", unique: true
    t.index ["message_id"], name: "index_message_citations_on_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "error_message"
    t.string "finish_reason"
    t.jsonb "grounding_metadata", default: {}
    t.datetime "processing_started_at"
    t.integer "role", null: false
    t.integer "status", default: 0, null: false
    t.integer "token_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["chat_id", "created_at"], name: "index_messages_on_chat_and_created_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["status"], name: "index_messages_on_status"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_projects_on_deleted_at"
    t.index ["name", "user_id"], name: "index_projects_on_name_and_user_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.bigint "current_project_id"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "full_name", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["current_project_id"], name: "index_users_on_current_project_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "gemini_file_search_stores"
  add_foreign_key "chats", "projects"
  add_foreign_key "chats", "users"
  add_foreign_key "documents", "gemini_file_search_stores"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
  add_foreign_key "gemini_file_search_stores", "projects"
  add_foreign_key "message_citations", "documents"
  add_foreign_key "message_citations", "messages"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "users", "projects", column: "current_project_id"
end
