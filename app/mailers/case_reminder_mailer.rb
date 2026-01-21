# frozen_string_literal: true

class CaseReminderMailer < ApplicationMailer
  def reminder_notification
    @notification = params[:notification]
    @recipient = params[:recipient]
    @case_reminder = @notification.params[:case_reminder]
    @time_until = @notification.params[:time_until]
    @legal_case = @case_reminder.legal_case
    @assigned_users = @case_reminder.users.where.not(id: @recipient.id)

    mail(
      to: @recipient.email,
      subject: t("case_reminder_mailer.reminder_notification.subject",
                 title: @case_reminder.title,
                 time: @time_until)
    )
  end
end
