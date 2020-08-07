# frozen_string_literal: true

require 'test_helper'

class LinkGroupRoleDelegationTest < ActiveSupport::TestCase
  test "Parent should be a FullGroup and child a SubGroup" do
    lsubgroup = ledger_subgroups(:group_dogs)
    lfullgroup = ledger_full_groups(:group_all)
    kDelegate = LinkGroupRoleDelegation.new(
      delegate_to: lsubgroup, subgroup: lfullgroup)
    assert_not(kDelegate.valid?, "Should check types of link endpoints.")
    assert_equal(3, kDelegate.errors.messages.count, "Should be some errors.")
    assert(kDelegate.errors.messages.include?(:creator))
    assert(kDelegate.errors.messages.include?(:nonfullgroup))
    assert(kDelegate.errors.messages.include?(:nonsubgroup))

    kDelegate = LinkGroupRoleDelegation.new(
      delegate_to: lfullgroup, subgroup: lsubgroup, creator_id: 0)
    assert(kDelegate.valid?)
    kDelegate.save!
  end
end
