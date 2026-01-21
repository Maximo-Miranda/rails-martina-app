# frozen_string_literal: true

class CreateLegalCases < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_cases do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :case_number, null: false
      t.string :court, null: false
      t.string :specialty
      t.string :status, default: "activo", null: false
      t.string :action_type
      t.date :filing_date

      t.string :plaintiff
      t.string :defendant
      t.string :plaintiff_lawyer
      t.string :defendant_lawyer

      t.string :lawyer_in_charge
      t.string :lawyer_phone
      t.string :lawyer_email
      t.string :lawyer_professional_card

      t.date :current_term_date
      t.date :last_action_date

      t.text :notes
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :legal_cases, :deleted_at
    add_index :legal_cases, :status
    add_index :legal_cases, :current_term_date
    add_index :legal_cases, %i[project_id case_number], unique: true, where: "deleted_at IS NULL",
              name: "idx_legal_cases_unique_case_number"
  end
end
