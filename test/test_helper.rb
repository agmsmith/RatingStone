# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require "minitest/reporters"
Minitest::Reporters.use!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Returns true if a test user is logged in.  Can't use magic name
    # "test_user_logged_in?" for this function since it breaks things.
    def tested_user_logged_in?
      !session[:user_id].nil?
    end

    # Log in as a particular user, for controller tests.
    def log_in_as(user)
      session[:user_id] = user.id
    end

    # Add more helper methods to be used by all tests here...
    include ApplicationHelper
  end
end

module ActionDispatch
  class IntegrationTest
    # Log in as a particular user via login page, for integration tests.
    # Fortunately the fixture users use 'password' as their password.
    def log_in_as(user, password: 'password', remember_me: '1')
      post(login_path, params: { session: {
        email: user.email,
        password: password,
        remember_me: remember_me,
      } })
    end
  end
end
