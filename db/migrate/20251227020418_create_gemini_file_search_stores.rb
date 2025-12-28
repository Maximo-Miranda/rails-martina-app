# frozen_string_literal: true

class CreateGeminiFileSearchStores < ActiveRecord::Migration[8.1]
  def change
    create_table :gemini_file_search_stores do |t|
      t.references :project, null: true, foreign_key: true
      t.string :gemini_store_name
      t.string :display_name, null: false
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.integer :active_documents_count, default: 0, null: false
      t.bigint :size_bytes, default: 0, null: false
      t.jsonb :metadata, default: {}
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :gemini_file_search_stores, :gemini_store_name, unique: true
    add_index :gemini_file_search_stores, :deleted_at
  end
end
