# frozen_string_literal: true

require 'test_helper'

class SiteLayoutTest < ActionDispatch::IntegrationTest
  test "layout links" do
    get root_path
    assert_template 'static_pages/home'
    assert_select "a[href=?]", root_path, count: 3
    assert_select "a[href=?]", about_path, count: 2
    assert_select "a[href=?]", contact_path, count: 2
    assert_select "a[href=?]", help_path, count: 2
    assert_select "a[href=?]", login_path, count: 2
    assert_select "a[href=?]", users_path, count: 0
    assert_select "a[href=?]", logout_path, count: 0
    get about_path
    assert_select "title", full_title("About")
    get contact_path
    assert_select "title", full_title("Contact")
    get signup_path
    assert_select "title", full_title("Sign Up")
    testing_user = users(:michael)
    log_in_as(testing_user)
    follow_redirect!
    assert_select "title", full_title(testing_user.name)
    get root_path
    assert_template 'static_pages/home'
    assert_select "a[href=?]", root_path, count: 3
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path, count: 2
    assert_select "a[href=?]", users_path, count: 2
    assert_select "a[href=?]", user_path(testing_user), count: 4
    assert_select "a[href=?]", edit_user_path(testing_user), count: 2
  end
end
