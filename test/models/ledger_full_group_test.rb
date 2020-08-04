# frozen_string_literal: true

require 'test_helper'

class LedgerFullGroupTest < ActiveSupport::TestCase
  def setup
    @group = ledger_full_groups(:group_all)
    @settings = @group.group_setting
  end

  test "Banned user should have no access" do
    luser = ledger_users(:undesirable_user)
    assert_not @group.creator_owner?(luser)
    LinkRole::ROLE_NAMES.each do |role_priority, role_name|
      if role_priority == LinkRole::BANNED
        assert(@group.role_test?(luser, role_priority),
          "Testing role #{role_name}, should have it.")
      else
        assert_not(@group.role_test?(luser, role_priority),
          "Testing role #{role_name}, should not have it.")
      end
    end
  end

  test "Various users have certain roles" do
    luser = ledger_users(:outsider_user)
    assert_equal(@group.get_role(luser), LinkRole::READER)
    luser = ledger_users(:reader_user)
    assert_equal(@group.get_role(luser), LinkRole::READER)
    luser = ledger_users(:undesirable_user)
    assert_equal(@group.get_role(luser), LinkRole::BANNED)
    luser = ledger_users(:group_creator_user)
    assert_equal(@group.get_role(luser), LinkRole::CREATOR)
    luser = ledger_users(:group_owner_user)
    assert_equal(@group.get_role(luser), LinkRole::OWNER)
    luser = ledger_users(:meta_moderator_user)
    assert_equal(@group.get_role(luser), LinkRole::META_MODERATOR)
    luser = ledger_users(:message_moderator_user)
    assert_equal(@group.get_role(luser), LinkRole::MESSAGE_MODERATOR)
    luser = ledger_users(:message_moderator2_user) # Both Banned and moderator.
    assert_equal(@group.get_role(luser), LinkRole::BANNED)
    luser = ledger_users(:member_moderator_user)
    assert_equal(@group.get_role(luser), LinkRole::MEMBER_MODERATOR)
    luser = ledger_users(:member_user)
    assert_equal(@group.get_role(luser), LinkRole::MEMBER)
  end
end
