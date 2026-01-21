# frozen_string_literal: true

class CreateCaseDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :case_documents do |t|
      t.references :case_notebook, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.references :document, foreign_key: true

      t.integer :item_number
      t.string :document_type, null: false
      t.string :name, null: false
      t.text :description
      t.integer :folio_start
      t.integer :folio_end
      t.integer :page_count
      t.date :document_date
      t.string :issuer

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :case_documents, :deleted_at
    add_index :case_documents, :document_type
    add_index :case_documents, %i[case_notebook_id item_number], unique: true, where: "deleted_at IS NULL",
              name: "idx_case_documents_unique_item"
  end
end
