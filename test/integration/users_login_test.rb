# frozen_string_literal: true

require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "login with invalid information" do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: "", password: "" } }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?, "Error displayed in Flash should disappear on next page."
  end

  test "login with valid user but wrong password" do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: @user.email, password: "WrongPassword" } }
    assert_not tested_user_logged_in?
    assert_template 'sessions/new'
    assert_not flash.empty?
  end

  test "login with valid information" do
    get login_path
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    assert tested_user_logged_in?
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@user)
    # Test logging out using the normal Rails way (requires browser Javascript).
    delete logout_path
    assert_not tested_user_logged_in?
    assert_redirected_to root_url
    # Simulate a user clicking logout in a second window while being logged out.
    delete logout_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "logout using GET /logout for non-javascript browsers" do
    get login_path
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    follow_redirect!
    assert tested_user_logged_in?
    get logout_path
    assert_not tested_user_logged_in?
    assert_redirected_to root_url
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert cookies[:remember_token]
    internal_user = @controller.current_user
    assert_equal internal_user.remember_token, cookies[:remember_token]
  end

  test "login without remembering" do
    # Log in to set the cookie.
    log_in_as(@user, remember_me: '1')
    # Log in again and verify that the cookie is deleted.
    log_in_as(@user, remember_me: '0')
    assert_empty cookies[:remember_token]
  end
end
