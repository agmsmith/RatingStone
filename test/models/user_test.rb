# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Example User", email: "user@example.com")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name needs to be present" do
    @user.name = "    "
    assert_not @user.valid?
  end

  test "email needs to be present" do
    @user.email = "    "
    assert_not @user.valid?
  end

  test "name shouldn't be too long" do
    @user.name = "a" * 51
    assert_not @user.valid?
    @user.name = "a" * 50
    assert @user.valid?
  end

  test "email shouldn't be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
    @user.email = "a" * 243 + "@example.com"
    assert @user.valid?
  end
end
