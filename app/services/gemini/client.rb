# frozen_string_literal: true

require "faraday"

module Gemini
  class Client
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

    class ApiError < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        @status = status
        @body = body
        super(message)
      end
    end

    class << self
      def create_store(display_name)
        post("fileSearchStores", { displayName: display_name })
      end

      def get_store(store_name)
        get(store_name)
      end

      def delete_store(store_name)
        response = connection.delete(normalize_path(store_name)) do |req|
          req.params["key"] = api_key
          req.params["force"] = "true"
        end

        # 403 = "store doesn't exist or no permission" - treat as successful deletion (idempotent)
        if response.status == 403
          Rails.logger.info "[Gemini::Client] Store #{store_name} not found or no permission (403), treating as deleted"
          return true
        end

        raise ApiError.new("Failed to delete store: #{response.status}", status: response.status, body: response.body) unless response.success?

        true
      end

      private

      def get(path)
        handle_response(connection.get(normalize_path(path)) { |req| req.params["key"] = api_key })
      end

      def post(path, body)
        handle_response(
          connection.post(normalize_path(path)) do |req|
            req.params["key"] = api_key
            req.body = body
          end
        )
      end

      def normalize_path(path)
        p = path.to_s
        p = p.sub(/\A#{Regexp.escape(BASE_URL)}\/?/, "")
        p = p.sub(/\A\/+/, "")
        p = p.split("?", 2).first
        p
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end

      def api_key
        @api_key ||= Rails.application.credentials.gemini_api_key.tap do |key|
          raise ApiError.new("GEMINI_API_KEY is not set in credentials") unless key
        end
      end

      def handle_response(response)
        unless response.success?
          raise ApiError.new(
            "Gemini File Search API Error: #{response.status} - #{response.body}",
            status: response.status,
            body: response.body
          )
        end

        response.body
      end
    end
  end
end
