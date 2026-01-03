# frozen_string_literal: true

require "faraday"

module Gemini
  class DocumentService
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
    UPLOAD_BASE_URL = "https://generativelanguage.googleapis.com/upload/v1beta"

    POLLING_MAX_ATTEMPTS = 60
    POLLING_INTERVAL_SECONDS = 5

    class UploadError < StandardError; end
    class DeleteError < StandardError; end
    class NotFoundError < StandardError; end

    class << self
      def upload(file_path:, store_remote_id:, display_name:, mime_type:, custom_metadata: {})
        store_path = normalize_store_path(store_remote_id)
        operation = start_upload(file_path, store_path, display_name, mime_type, custom_metadata)
        result = poll_until_complete(operation["name"], context: display_name)

        build_upload_result(result)
      rescue => e
        raise UploadError, "Upload failed: #{e.message}"
      end

      def delete(gemini_document_path)
        response = connection.delete(gemini_document_path) do |req|
          req.params["key"] = api_key
          req.params["force"] = "true"
        end

        return true if response.success? || response.status == 404

        raise DeleteError, "Delete failed: #{response.status} - #{response.body}"
      end

      def find(gemini_document_path)
        response = connection.get(gemini_document_path) do |req|
          req.params["key"] = api_key
        end

        raise NotFoundError, "Document not found" if response.status == 404
        raise "Get failed: #{response.status} - #{response.body}" unless response.success?

        response.body
      end

      def exists?(gemini_document_path)
        find(gemini_document_path)
        true
      rescue NotFoundError
        false
      end

      def supported_content_types
        Document::SUPPORTED_CONTENT_TYPES.keys
      end

      def max_file_size
        Document::MAX_FILE_SIZE
      end

      private

      def start_upload(file_path, store_path, display_name, mime_type, _custom_metadata)
        # Note: customMetadata is NOT supported in uploadToFileSearchStore endpoint
        # It would require a two-step process: upload file first, then importFile with metadata
        # For now, we skip custom_metadata - it can be stored locally in the Document model
        file_content = File.binread(file_path)

        response = upload_connection.post("#{store_path}:uploadToFileSearchStore") do |req|
          req.params["key"] = api_key
          req.params["displayName"] = display_name
          req.headers["Content-Type"] = mime_type
          req.headers["X-Goog-Upload-Protocol"] = "raw"
          req.body = file_content
        end

        raise "Upload request failed: #{response.status} - #{response.body}" unless response.success?

        JSON.parse(response.body)
      end

      # Note: This method is kept for future use if we implement two-step upload with importFile
      def add_custom_metadata_params(req, custom_metadata)
        metadata_index = 0
        custom_metadata.each do |key, value|
          next if value.blank?

          case value
          when Array
            req.params["customMetadata[#{metadata_index}].key"] = key.to_s
            value.each_with_index do |v, i|
              req.params["customMetadata[#{metadata_index}].stringListValue.values[#{i}]"] = v.to_s
            end
          when Numeric
            req.params["customMetadata[#{metadata_index}].key"] = key.to_s
            req.params["customMetadata[#{metadata_index}].numericValue"] = value
          else
            req.params["customMetadata[#{metadata_index}].key"] = key.to_s
            req.params["customMetadata[#{metadata_index}].stringValue"] = value.to_s
          end
          metadata_index += 1
        end
      end

      def poll_until_complete(operation_name, context:)
        POLLING_MAX_ATTEMPTS.times do |attempt|
          result = fetch_operation(operation_name)

          return result if result["done"] && result["error"].nil?

          if result["error"]
            raise "Operation failed: #{result.dig('error', 'message')}"
          end

          log_progress(context, attempt)
          sleep(POLLING_INTERVAL_SECONDS)
        end

        raise "Operation timed out after #{POLLING_MAX_ATTEMPTS * POLLING_INTERVAL_SECONDS}s"
      end

      def fetch_operation(operation_name)
        response = connection.get(operation_name) do |req|
          req.params["key"] = api_key
        end

        raise "Failed to fetch operation: #{response.status}" unless response.success?

        response.body
      end

      def build_upload_result(operation_result)
        response = operation_result["response"]
        doc_name = response["documentName"]

        raise "No document name in response" if doc_name.blank?

        {
          remote_id: doc_name.split("/").last,
          gemini_document_path: doc_name,
          size_bytes: response["sizeBytes"]&.to_i,
        }
      end

      def normalize_store_path(store_remote_id)
        return store_remote_id if store_remote_id.start_with?("fileSearchStores/")

        "fileSearchStores/#{store_remote_id}"
      end

      def log_progress(context, attempt)
        Rails.logger.info("[Gemini::DocumentService] Processing '#{context}' (#{attempt + 1}/#{POLLING_MAX_ATTEMPTS})")
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end

      def upload_connection
        @upload_connection ||= Faraday.new(url: UPLOAD_BASE_URL) do |f|
          f.adapter Faraday.default_adapter
        end
      end

      def api_key
        @api_key ||= Rails.application.credentials.gemini_api_key.tap do |key|
          raise "GEMINI_API_KEY not configured in credentials" unless key
        end
      end
    end
  end
end
