# frozen_string_literal: true

require "test_helper"

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template "password_resets/new"
    assert_select "input[name=?]", "password_reset[email]"
    # Invalid email
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template "password_resets/new"
    # Valid email
    post password_resets_path,
      params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # Password reset form has looked up the user from the email address (new
    # object in its @user) and made a reset token in it (not in our @user).
    user = assigns(:user)
    assert_equal @user, user
    assert_not_same @user, user
    # Wrong email
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # Inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # Right email, wrong token
    get edit_password_reset_path("wrong token", email: user.email)
    assert_redirected_to root_url
    # Right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template "password_resets/edit"
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # Invalid password & confirmation
    patch password_reset_path(user.reset_token),
      params: {
        email: user.email,
        user: {
          password: "foobaz",
          password_confirmation: "barquux",
        },
      }
    assert_select "div#error_explanation"
    # Empty password
    patch password_reset_path(user.reset_token),
      params: {
        email: user.email,
        user: {
          password: "",
          password_confirmation: "",
        },
      }
    assert_select "div#error_explanation"
    assert_not_nil user.reload.reset_digest
    # Valid password & confirmation
    patch password_reset_path(user.reset_token),
      params: {
        email: user.email,
        user: {
          password: "foobaz",
          password_confirmation: "foobaz",
        },
      }
    assert tested_user_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    # Reset should only be useable one time; digest should be wiped out.
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/password reset ignored/i, response.body)
    assert_nil user.reload.reset_digest
  end

  test "expired token" do
    get new_password_reset_path
    post password_resets_path,
      params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
      params: {
        email: @user.email,
        user: {
          password: "foobar",
          password_confirmation: "foobar",
        },
      }
    assert_response :redirect
    follow_redirect!
    assert_match(/reset has expired/i, response.body)
  end
end
