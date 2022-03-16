# frozen_string_literal: true

require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template "users/edit"
    patch user_path(@user), params: { user: {
      name: "",
      email: "foo@invalid",
      password: "foo",
      password_confirmation: "bar",
    } }
    assert_template "users/edit"
    assert_select "div.alert", "The form contains 4 errors."
    assert_select "div#error_explanation" do
      assert_select "li", 4, "Should be 4 errors in our bad edit."
    end
  end

  test "successful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template "users/edit"
    name = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: {
      name: name,
      email: email,
      password: "",
      password_confirmation: "",
    } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end

  test "name edit without enough rating points" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template "users/edit"
    @user.ledger_user.request_full_point_recalculation # Actually has no points.
    name_old = @user.name
    name_new = "Foo Bar"
    email_old = @user.email
    email_new = "foo@bar.com"
    assert_raise(RatingStoneErrors) do
      patch user_path(@user), params: { user: {
        name: name_new,
        email: email_new,
        password: "",
        password_confirmation: "",
      } }
    end
    @user.reload
    assert_equal name_old, @user.name
    assert_equal email_old, @user.email
  end

  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    assert_redirected_to login_url
    assert_equal edit_user_url(@user), session[:forwarding_url]
    follow_redirect!
    assert_template "sessions/new"
    log_in_as(@user)
    assert session[:forwarding_url].nil?
    assert_redirected_to edit_user_url(@user)
    assert session[:forwarding_url].nil?
    name = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: {
      name: name,
      email: email,
      password: "",
      password_confirmation: "",
    } }
    assert_not flash.empty?
    assert session[:forwarding_url].nil?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end
end
