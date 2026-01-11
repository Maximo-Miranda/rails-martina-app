# frozen_string_literal: true

require "faraday"

module Gemini
  class ChatService
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
    MODEL_ID = "gemini-3-flash-preview"

    DEFAULT_TEMPERATURE = 0.0
    DEFAULT_TOP_K = 40
    DEFAULT_TOP_P = 0.95
    DEFAULT_MAX_OUTPUT_TOKENS = 8192

    class ChatError < StandardError
      attr_reader :status, :body, :finish_reason

      def initialize(message, status: nil, body: nil, finish_reason: nil)
        @status = status
        @body = body
        @finish_reason = finish_reason
        super(message)
      end
    end

    class << self
      # Sends a message to Gemini with file search context
      #
      # @param chat [Chat] the chat instance
      # @param user_message [String] the new user message
      # @param options [Hash] optional generation config overrides
      # @return [Hash] { content:, grounding_metadata:, citations:, token_count: }
      def send_message(chat:, user_message:, options: {})
        store_name = chat.gemini_file_search_store.gemini_store_name
        history = chat.history_for_context

        payload = build_payload(user_message, store_name, history, options)
        response = post_generate_content(payload)

        process_response(response, chat.project)
      end

      private

      def post_generate_content(payload)
        response = connection.post("models/#{MODEL_ID}:generateContent") do |req|
          req.params["key"] = api_key
          req.body = payload
        end

        handle_response(response)
      end

      def build_payload(user_message, store_name, history, options)
        {
          systemInstruction: build_system_instruction,
          contents: build_contents(user_message, history),
          tools: build_tools(store_name),
          generationConfig: build_generation_config(options),
        }
      end

      def build_system_instruction
        {
          parts: [
            {
              text: I18n.t("chats.system_prompt"),
            },
          ],
        }
      end

      def build_contents(user_message, history)
        contents = history.map do |msg|
          { role: msg[:role], parts: [ { text: msg[:content] } ] }
        end

        contents << { role: "user", parts: [ { text: user_message } ] }
        contents
      end

      def build_tools(store_name)
        [
          {
            fileSearch: {
              fileSearchStoreNames: [ store_name ],
            },
          },
        ]
      end

      def build_generation_config(options)
        {
          temperature: options[:temperature] || DEFAULT_TEMPERATURE,
          topK: options[:top_k] || DEFAULT_TOP_K,
          topP: options[:top_p] || DEFAULT_TOP_P,
          maxOutputTokens: options[:max_output_tokens] || DEFAULT_MAX_OUTPUT_TOKENS,
          responseMimeType: "text/plain",
        }
      end

      def handle_response(response)
        unless response.success?
          error_message = response.body.dig("error", "message") || response.body.to_s
          raise ChatError.new(
            "Gemini API Error: #{error_message}",
            status: response.status,
            body: response.body
          )
        end

        response.body
      end

      def process_response(data, project)
        candidate = data.dig("candidates", 0)

        if candidate.nil?
          raise ChatError.new(I18n.t("chats.errors.no_response"))
        end

        content = candidate.dig("content", "parts", 0, "text") || ""
        finish_reason = candidate["finishReason"]
        grounding_metadata = candidate["groundingMetadata"] || {}

        content = handle_empty_content(content, finish_reason)

        citations = CitationExtractor.extract(
          grounding_metadata: grounding_metadata,
          project: project
        )

        {
          content: content,
          grounding_metadata: grounding_metadata,
          citations: citations,
          token_count: extract_token_count(data),
          finish_reason: finish_reason,
        }
      end

      def handle_empty_content(content, finish_reason)
        return content if content.present?

        case finish_reason
        when "SAFETY"
          I18n.t("chats.errors.blocked_safety")
        when "RECITATION"
          I18n.t("chats.errors.blocked_recitation")
        when "MAX_TOKENS"
          I18n.t("chats.errors.max_tokens")
        else
          I18n.t("chats.errors.no_relevant_info")
        end
      end

      def extract_token_count(data)
        usage = data["usageMetadata"] || {}
        usage["totalTokenCount"] || 0
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
          f.options.timeout = 120
          f.options.open_timeout = 30
        end
      end

      def api_key
        @api_key ||= Rails.application.credentials.gemini_api_key.tap do |key|
          raise ChatError.new("GEMINI_API_KEY is not set in credentials") unless key
        end
      end
    end
  end
end
