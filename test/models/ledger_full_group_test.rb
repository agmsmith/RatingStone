# frozen_string_literal: true

require 'test_helper'

class LedgerFullGroupTest < ActiveSupport::TestCase
  def setup
    @group = ledger_full_groups(:group_all)
    @settings = @group.group_setting
  end

  test "Banned should have no access" do
    luser = ledger_users(:undesirable_user)
    assert_not @group.creator_owner?(luser)
    LinkRole::ROLE_NAMES.each do |role_priority, role_name|
      assert_not(@group.permission?(luser, role_priority), role_name)
    end
  end
end
