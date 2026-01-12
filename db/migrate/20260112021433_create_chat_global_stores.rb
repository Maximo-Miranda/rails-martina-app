# frozen_string_literal: true

class CreateChatGlobalStores < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_global_stores do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :gemini_file_search_store, null: false, foreign_key: true

      t.timestamps
    end

    add_index :chat_global_stores, %i[chat_id gemini_file_search_store_id],
              unique: true, name: "index_chat_global_stores_unique"
  end
end
