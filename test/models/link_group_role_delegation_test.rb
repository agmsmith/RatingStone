# frozen_string_literal: true

require 'test_helper'

class LinkGroupRoleDelegationTest < ActiveSupport::TestCase
  test "Parent should be a FullGroup and child a SubGroup" do
    lsubgroup = ledger_subgroups(:group_dogs)
    lfullgroup = ledger_full_groups(:group_all)
    kdelegate = LinkGroupRoleDelegation.new(delegate_to: lsubgroup,
      subgroup: lfullgroup)
    assert_not(kdelegate.valid?, "Should check types of link endpoints.")
    assert_equal(3, kdelegate.errors.messages.count, "Should be some errors.")
    assert(kdelegate.errors.messages.include?(:creator))
    assert(kdelegate.errors.messages.include?(:nonfullgroup))
    assert(kdelegate.errors.messages.include?(:nonsubgroup))

    kdelegate = LinkGroupRoleDelegation.new(delegate_to: lfullgroup,
      subgroup: lsubgroup, creator_id: 0)
    assert(kdelegate.valid?)
    kdelegate.save!
  end
end
