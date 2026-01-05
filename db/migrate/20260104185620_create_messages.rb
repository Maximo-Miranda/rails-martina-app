# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :role, null: false
      t.text :content, null: false
      t.jsonb :grounding_metadata, default: {}
      t.integer :status, default: 0, null: false
      t.integer :token_count, default: 0
      t.datetime :processing_started_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, :deleted_at
    add_index :messages, :status
    add_index :messages, %i[chat_id created_at], name: "index_messages_on_chat_and_created_at"
  end
end
