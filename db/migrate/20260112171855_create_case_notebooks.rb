# frozen_string_literal: true

class CreateCaseNotebooks < ActiveRecord::Migration[8.1]
  def change
    create_table :case_notebooks do |t|
      t.references :legal_case, null: false, foreign_key: true

      t.string :notebook_type, null: false
      t.string :code, null: false
      t.string :description
      t.integer :volume, default: 1
      t.integer :folio_count, default: 0

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :case_notebooks, :deleted_at
    add_index :case_notebooks, %i[legal_case_id code volume], unique: true, where: "deleted_at IS NULL",
              name: "idx_case_notebooks_unique"
  end
end
