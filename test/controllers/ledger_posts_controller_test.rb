# frozen_string_literal: true

require 'test_helper'

class LedgerPostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @ledger_post = ledger_posts(:lpost_one)
  end

  test "should redirect create when not logged in" do
    assert_no_difference 'LedgerBase.count' do
      post ledger_posts_path, params:
        { ledger_post: { content: "Lorem ipsum", subject: "My Subject" } }
    end
    assert_redirected_to login_url
  end
end
