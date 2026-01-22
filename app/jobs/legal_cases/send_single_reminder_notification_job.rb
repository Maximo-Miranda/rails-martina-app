# frozen_string_literal: true

module LegalCases
  class SendSingleReminderNotificationJob < ApplicationJob
    queue_as :notifications

    NOTIFICATION_WINDOWS = {
      notification_3d: { time_until: "3 días", threshold: 3.days },
      notification_1d: { time_until: "1 día", threshold: 1.day },
      notification_4h: { time_until: "4 horas", threshold: 4.hours },
      notification_1h: { time_until: "1 hora", threshold: 1.hour },
    }.freeze

    def perform(case_reminder_id, notification_type)
      reminder = CaseReminder.kept.find_by(id: case_reminder_id)
      return unless reminder
      return if reminder.acknowledged?

      window = NOTIFICATION_WINDOWS[notification_type.to_sym]
      return unless window

      send_notifications(reminder, notification_type, window)
      clear_job_id(reminder, notification_type)
    end

    private

    def send_notifications(reminder, notification_type, window)
      reminder.case_reminder_users.pending.includes(:user).find_each do |reminder_user|
        CaseReminderNotifier.with(
          case_reminder: reminder,
          time_until: window[:time_until],
          notification_type: notification_type.to_sym
        ).deliver(reminder_user.user)
      end
    end

    def clear_job_id(reminder, notification_type)
      job_id_column = "#{notification_type}_job_id"
      reminder.update_column(job_id_column, nil)
    end
  end
end
