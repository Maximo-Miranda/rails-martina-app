# frozen_string_literal: true

require "vcr"
require "json"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test", "vcr_cassettes")
  config.hook_into :faraday
  config.ignore_localhost = true

  config.filter_sensitive_data("<GEMINI_API_KEY>") do
    Rails.application.credentials.gemini_api_key
  end

  config.register_request_matcher :gemini_request do |request_1, request_2|
    uri1 = URI(request_1.uri)
    uri2 = URI(request_2.uri)

    next false unless request_1.method == request_2.method
    next false unless uri1.host == uri2.host
    next false unless uri1.path == uri2.path

    b1 = request_1.body.to_s
    b2 = request_2.body.to_s
    next true if b1.empty? && b2.empty?

    begin
      j1 = JSON.parse(b1)
      j2 = JSON.parse(b2)

      j1.delete("displayName")
      j2.delete("displayName")

      j1 == j2
    rescue JSON::ParserError
      b1 == b2
    end
  end

  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[gemini_request],
  }
end

module VcrTestHelper
  def with_vcr_cassette(name, options = {}, &block)
    VCR.use_cassette(name, options, &block)
  end
end
