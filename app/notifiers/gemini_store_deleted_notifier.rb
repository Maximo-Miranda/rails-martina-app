# frozen_string_literal: true

class GeminiStoreDeletedNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
    config.stream = -> { recipient }
    config.message = -> {
      {
        type: "store_deleted",
        store_id: params[:store].id,
        display_name: params[:store].display_name,
        message: t(".message", name: params[:store].display_name),
      }
    }
  end

  notification_methods do
    def message
      t(".message", name: params[:store].display_name)
    end

    def url
      nil # Will be implemented based on routing
    end
  end
end
