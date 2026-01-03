# frozen_string_literal: true

class DocumentDeletedNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
    config.stream = -> { recipient }
    config.message = -> {
      {
        type: "document_deleted",
        document_id: params[:document].id,
        display_name: params[:document].display_name,
        message: t(".message", name: params[:document].display_name),
      }
    }
  end

  notification_methods do
    def message
      t(".message", name: params[:document].display_name)
    end

    def url
      nil
    end
  end
end
