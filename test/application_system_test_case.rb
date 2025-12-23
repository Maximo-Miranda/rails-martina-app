require "test_helper"
require "capybara"
require "capybara/minitest"
require "capybara-playwright-driver"

def ensure_vite_built!
  cache_file = Rails.root.join("tmp/cache/vite/last-build-test.json")

  vite_built = cache_file.exist? && begin
    cache_data = JSON.parse(cache_file.read)
    cache_data["success"] == true
  rescue JSON::ParserError
    false
  end

  unless vite_built
    success = system("bin/vite build --mode test")
    abort("Vite build failed!") unless success
  end
end

ensure_vite_built!

BROWSER = ENV.fetch("BROWSER", "firefox").to_sym

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
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Rails.application.routes.url_helpers

  fixtures :all

  def teardown
    Capybara.reset_sessions!
  end
end
