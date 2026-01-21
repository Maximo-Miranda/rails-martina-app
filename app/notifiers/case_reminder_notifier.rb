# frozen_string_literal: true

class CaseReminderNotifier < Noticed::Event
  deliver_by :email do |config|
    config.mailer = "CaseReminderMailer"
    config.method = :reminder_notification
  end

  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
    config.stream = -> { recipient }
    config.message = -> {
      reminder = params[:case_reminder]
      {
        type: "case_reminder",
        reminder_id: reminder.id,
        legal_case_id: reminder.legal_case_id,
        title: reminder.title,
        time_until: params[:time_until],
        message: t(".message", title: reminder.title, time: params[:time_until]),
      }
    }
  end

  required_params :case_reminder, :time_until, :notification_type

  notification_methods do
    def message
      t(".message", title: params[:case_reminder].title, time: params[:time_until])
    end

    def url
      nil
    end
  end
end
