# frozen_string_literal: true

require "test_helper"

class UsersProfileTest < ActionDispatch::IntegrationTest
  include ApplicationHelper
  include Pagy::Backend

  def setup
    @user = users(:michael)
    log_in_as(@user)
    40.times do |i|
      LedgerPost.create!(
        creator: @user.ledger_user,
        subject: "Post #{i}",
        content: "This is a test post ##{i} by Michael.",
      )
    end
  end

  test "profile display" do
    get user_path(@user)
    assert_template "users/show"
    assert_select "title", full_title(@user.name)
    assert_select "h1", text: @user.name
    assert_select "img.gravatar"
    _pagy, lposts = pagy(
      LedgerPost.where(
        creator_id: @user.ledger_user_id,
        deleted: false,
      ),
      page: 1,
    )
    assert_match "#{lposts.count} Ledger Posts by #{@user.name}", response.body
    assert_select "nav.pagy-bootstrap ul.pagination", count: 2
    _pagy, page_of_posts = pagy(lposts, page: 1)
    page_of_posts.each do |lpost|
      assert_match lpost.content, response.body
    end
  end
end
