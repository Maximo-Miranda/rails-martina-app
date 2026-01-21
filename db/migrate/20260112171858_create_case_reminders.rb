# frozen_string_literal: true

class CreateCaseReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :case_reminders do |t|
      t.references :legal_case, null: false, foreign_key: true
      t.references :court_order, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.string :reminder_type, null: false
      t.string :custom_type
      t.text :description
      t.datetime :reminder_at, null: false
      t.string :location

      # Job IDs for scheduled notifications (to cancel them if needed)
      t.string :notification_3d_job_id
      t.string :notification_1d_job_id
      t.string :notification_4h_job_id
      t.string :notification_1h_job_id

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :case_reminders, :deleted_at
    add_index :case_reminders, :reminder_at
    add_index :case_reminders, :reminder_type
  end
end
