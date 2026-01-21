# frozen_string_literal: true

class CreateCaseReminderUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :case_reminder_users do |t|
      t.references :case_reminder, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.boolean :acknowledged, default: false
      t.datetime :acknowledged_at

      t.timestamps
    end

    add_index :case_reminder_users, %i[case_reminder_id user_id], unique: true,
              name: "idx_case_reminder_users_unique"
  end
end
