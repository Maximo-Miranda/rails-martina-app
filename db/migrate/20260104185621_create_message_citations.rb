# frozen_string_literal: true

class CreateMessageCitations < ActiveRecord::Migration[8.1]
  def change
    create_table :message_citations do |t|
      t.references :message, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.integer :pages, array: true, default: []
      t.text :text_snippet
      t.decimal :confidence_score, precision: 5, scale: 4

      t.timestamps
    end

    add_index :message_citations, %i[message_id document_id],
              unique: true,
              name: "index_message_citations_uniqueness"
  end
end
