# frozen_string_literal: true

require 'test_helper'

class LedgerObjectsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @ledger_post = ledger_posts(:lpost_one)
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'LedgerBase.count' do
      delete ledger_object_path(@ledger_post)
    end
    assert(!@ledger_post.deleted)
    assert_redirected_to login_url
  end

  test "should redirect destroy for wrong LedgerPost owner" do
    log_in_as(users(:michael))
    assert_no_difference 'LedgerBase.count' do
      delete ledger_object_path(@ledger_post)
    end
    assert(!@ledger_post.deleted)
    assert_redirected_to root_url
  end

  test "should destroy for right LedgerPost owner" do
    log_in_as(users(:michael))
    lpost = LedgerPost.new(creator: users(:michael).ledger_user,
      content: "A test post from Michael.")
    lpost.save!
    assert_difference 'LedgerBase.count', 1 do
      delete ledger_object_path(lpost)
    end
    lpost.reload
    assert(lpost.deleted)
    assert_redirected_to root_url
  end

  test "should fail to destroy unknown object" do
    log_in_as(users(:michael))
    assert_raise(ActiveRecord::RecordNotFound) do
      delete ledger_object_path(12345678)
    end
  end

  test "should redirect undelete for wrong LedgerPost owner" do
    log_in_as(users(:michael))
    assert_no_difference 'LedgerBase.count' do
      post undelete_ledger_object_path(@ledger_post)
    end
    assert_redirected_to root_url
  end
end
