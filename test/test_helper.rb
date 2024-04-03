# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def mock_enviroment(env: "test", partial_env_hash: {})
      old_env_mode = Rails.env
      old_env = ENV.to_hash

      Rails.env = env
      ENV.update(partial_env_hash)

      begin
        yield
      ensure
         Rails.env = old_env_mode
         ENV.replace(old_env)
      end
    end

  end
end
