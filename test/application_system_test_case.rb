# frozen_string_literal: true

require "test_helper"
require "capybara"
require "capybara/minitest"
require "capybara-playwright-driver"
require "database_cleaner/active_record"

Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

def ensure_vite_built!
  cache_file = Rails.root.join("tmp/cache/vite/last-build-test.json")

  vite_built = cache_file.exist? && begin
    cache_data = JSON.parse(cache_file.read)
    cache_data["success"] == true
  rescue JSON::ParserError
    false
  end

  return if vite_built
    success = system("bin/vite build --mode test")
    abort("Vite build failed!") unless success
end

ensure_vite_built!

BROWSER = ENV.fetch("BROWSER", "firefox").to_sym.freeze

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: BROWSER,
    headless: ENV.fetch("HEADLESS", "true") == "true",
    playwright_cli_executable_path: "./node_modules/.bin/playwright"
  )
end

Capybara.default_driver = :playwright
Capybara.default_max_wait_time = 10
Capybara.app = Rails.application

class ApplicationSystemTestCase < ActiveSupport::TestCase
  include SystemTestHelper
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Rails.application.routes.url_helpers

  self.use_transactional_tests = false

  fixtures :all

  def before_setup
    super
    # Use :async adapter for system tests to support retry_on with wait:
    # The :inline adapter doesn't support scheduling jobs for the future
    ActiveJob::Base.queue_adapter = :async
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    setup_fixtures
  end

  def after_teardown
    Capybara.reset_sessions!
    DatabaseCleaner.clean
    super
  end
end
