# frozen_string_literal: true

module Gemini
  class DeleteStoreJob < ApplicationJob
    queue_as :default

    retry_on Gemini::Client::ApiError, wait: 5.seconds, attempts: 5
    retry_on Faraday::Error, wait: 5.seconds, attempts: 5

    # Executes when retry_on attempts are exhausted.
    # Ref: https://guides.rubyonrails.org/active_job_basics.html#callbacks
    after_discard do |job, exception|
      store = GeminiFileSearchStore.find_by(id: job.arguments.first)
      handle_failure(store, exception) if store
    end

    def perform(store_id, user_id = nil)
      store = GeminiFileSearchStore.find_by(id: store_id)
      return unless store
      return if store.discarded?

      if store.gemini_store_name.present?
        Gemini::Client.delete_store(store.gemini_store_name)
      end

      store.update!(status: :deleted)
      store.discard!

      Rails.configuration.event_store.publish(
        Gemini::StoreDeleted.new(data: {
          store_id: store.id,
          project_id: store.project_id,
          gemini_store_name: store.gemini_store_name,
          user_id: user_id,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )

      Rails.logger.info "[Gemini::DeleteStoreJob] Store deleted successfully: #{store.gemini_store_name}"
    end

    private

    def handle_failure(store, error)
      store.update!(
        status: :failed,
        error_message: "Deletion failed: #{error.message}"
      )

      Rails.configuration.event_store.publish(
        Gemini::StoreDeletionFailed.new(data: {
          store_id: store.id,
          project_id: store.project_id,
          gemini_store_name: store.gemini_store_name,
          error_message: error.message,
          user_id: job.arguments.second,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )

      Rails.logger.error "[Gemini::DeleteStoreJob] Store deletion failed after #{executions} attempts: #{error.message}"
    end
  end
end
