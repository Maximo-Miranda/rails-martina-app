# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :display_name, null: false
      t.string :content_type, null: false
      t.bigint :size_bytes, null: false
      t.string :file_hash, null: false
      t.integer :status, default: 0, null: false
      t.string :remote_id
      t.string :gemini_document_path
      t.references :project, foreign_key: true
      t.references :gemini_file_search_store, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.jsonb :custom_metadata, default: {}
      t.text :error_message
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :documents, %i[file_hash gemini_file_search_store_id],
              unique: true,
              where: "deleted_at IS NULL",
              name: "idx_documents_hash_store_unique"
    add_index :documents, :remote_id, unique: true, where: "remote_id IS NOT NULL"
    add_index :documents, :deleted_at
    add_index :documents, :status
  end
end
