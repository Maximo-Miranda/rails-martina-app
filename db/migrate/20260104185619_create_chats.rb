# frozen_string_literal: true

class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :gemini_file_search_store, null: false, foreign_key: true
      t.string :title
      t.integer :status, default: 0, null: false
      t.integer :messages_count, default: 0, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :chats, :deleted_at
    add_index :chats, :status
    add_index :chats, %i[project_id user_id], name: "index_chats_on_project_and_user"
    add_index :chats, %i[user_id created_at], name: "index_chats_on_user_and_created_at"
  end
end
