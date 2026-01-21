# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/inertia_test_helper"
require_relative "support/vcr_setup"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Disable parallelization due to macOS segfault with pg gem + Ruby 3.4.7
    # The crash occurs during fork with Kerberos system plugins
    # This is a known issue on macOS with forked processes
    # parallelize(workers: :number_of_processors)

    fixtures :all

    include VcrTestHelper
    include ActiveJob::TestHelper
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include InertiaTestHelper
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
