# frozen_string_literal: true

require 'test_helper'

class SessionsHelperTest < ActionView::TestCase
  def setup
    @user = users(:michael)
    remember(@user) # Only permanent cookie set, no session cookie.
  end

  test "current_user returns right user when session cookie is nil" do
    assert_not tested_user_logged_in?
    assert_equal @user, current_user
    assert logged_in?
    assert tested_user_logged_in?
  end

  test "current_user returns nil when remember digest is wrong" do
    @user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user
  end
end
