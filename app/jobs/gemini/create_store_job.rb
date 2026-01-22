# frozen_string_literal: true

module Gemini
  class CreateStoreJob < ApplicationJob
    queue_as :gemini

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
      return if store.active?

      response = Gemini::Client.create_store(store.display_name)
      gemini_store_name = response["name"]

      store.update!(
        gemini_store_name: gemini_store_name,
        status: :active,
        error_message: nil
      )

      Rails.configuration.event_store.publish(
        Gemini::StoreCreated.new(data: {
          store_id: store.id,
          project_id: store.project_id,
          gemini_store_name: gemini_store_name,
          display_name: store.display_name,
          user_id: user_id,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )

      Rails.logger.info "[Gemini::CreateStoreJob] Store created successfully: #{gemini_store_name}"
    end

    private

    def handle_failure(store, error)
      store.update!(
        status: :failed,
        error_message: error.message
      )

      Rails.configuration.event_store.publish(
        Gemini::StoreCreationFailed.new(data: {
          store_id: store.id,
          project_id: store.project_id,
          error_message: error.message,
          user_id: arguments.second,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )

      Rails.logger.error "[Gemini::CreateStoreJob] Store creation failed after #{executions} attempts: #{error.message}"
    end
  end
end
