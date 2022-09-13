# frozen_string_literal: true

require "test_helper"

class LinkRoleTest < ActiveSupport::TestCase
  test "Odd role numbers" do
    krole = LinkRole.new(group: ledger_subgroups(:group_dogs),
      user: ledger_posts(:lpost_two), priority: "52xxx",)
    assert_not(krole.valid?, "Should check types of link endpoints.")
    assert_equal(3, krole.errors.messages.count, "Should be some errors.")
    assert(krole.errors.messages.include?(:creator))
    assert(krole.errors.messages.include?(:nongroup))
    assert(krole.errors.messages.include?(:nonuser))

    krole = LinkRole.new(group: ledger_full_groups(:group_all),
      user: ledger_users(:member_user), creator: ledger_users(:member_user),
      priority: 52,)
    assert(krole.valid?)
    krole.save!
    assert(krole.description.include?(
      "is a message moderator (a nonstandard 52) in ",
    ))

    krole = LinkRole.new(group: ledger_full_groups(:group_all),
      user: ledger_users(:member_user), creator: ledger_users(:member_user),
      priority: 50,)
    krole.save!
    assert(krole.description.include?("is a message moderator in "))
  end
end
