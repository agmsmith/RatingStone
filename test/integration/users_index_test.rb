# frozen_string_literal: true

require "test_helper"

class UsersIndexTest < ActionDispatch::IntegrationTest
  include Pagy::Backend

  def setup
    @user = users(:michael)
  end

  test "index including pagination" do
    log_in_as(@user)
    get users_path
    assert_template "users/index"
    assert_select "nav.pagy-bootstrap ul.pagination", count: 2
    _pagy, page_of_users = pagy(User.all, page: 1)
    page_of_users.each do |user|
      assert_select "a[href=?]", user_path(user), text: user.name
    end
  end
end
