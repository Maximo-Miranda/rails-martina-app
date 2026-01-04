# frozen_string_literal: true

class DocumentUploadFailedNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
    config.stream = -> { recipient }
    config.message = -> {
      {
        type: "document_upload_failed",
        document_id: params[:document].id,
        display_name: params[:document].display_name,
        error: params[:document].error_message,
        message: t(".message", name: params[:document].display_name),
      }
    }
  end

  notification_methods do
    def message
      t(".message", name: params[:document].display_name)
    end
  end
end
