# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require "minitest/reporters"
Minitest::Reporters.use!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Returns true if a test user is logged in.  Can't use magic name
  # "test_user_logged_in?" for this function since it breaks things.
  def tested_user_logged_in?
    !session[:user_id].nil?
  end

  # Add more helper methods to be used by all tests here...
  include ApplicationHelper
end
