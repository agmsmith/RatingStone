# frozen_string_literal: true

require 'test_helper'

class LedgerFullGroupTest < ActiveSupport::TestCase
  def setup
    @group = ledger_full_groups(:group_all)
    @settings = @group.group_setting
  end

  test "Owner and creator should have group access" do
    assert @group.creator_owner?(ledger_users(:group_creator_user))
    assert @group.creator_owner?(ledger_users(:group_owner_user))
    assert_not @group.creator_owner?(ledger_users(:message_moderator_user))
    assert_not @group.creator_owner?(ledger_users(:member_moderator_user))
    assert_not @group.creator_owner?(ledger_users(:member_user))
    assert_not @group.creator_owner?(ledger_users(:some_user))
    assert_not @group.creator_owner?(ledger_users(:root_ledger_user))
    assert_raise(SecurityError, "Passing in a Post instead of a LedgerUser") do
      @group.creator_owner?(ledger_posts(:lpost_one))
    end
    assert_raise(SecurityError, "Passing in nil instead of a LedgerUser") do
      @group.creator_owner?(nil)
    end
  end
end
