# frozen_string_literal: true

class CaseReminderUser < ApplicationRecord
  belongs_to :case_reminder
  belongs_to :user

  validates :user_id, uniqueness: { scope: :case_reminder_id }

  scope :pending, -> { where(acknowledged: false) }
  scope :acknowledged_users, -> { where(acknowledged: true) }

  def acknowledge!
    return if acknowledged?

    update!(acknowledged: true, acknowledged_at: Time.current)
  end
end
