require 'test_helper'

class LedgerPostControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get ledger_post_create_url
    assert_response :success
  end

  test "should get destroy" do
    get ledger_post_destroy_url
    assert_response :success
  end

end
