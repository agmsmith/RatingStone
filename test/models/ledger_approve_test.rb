# frozen_string_literal: true

require 'test_helper'

class LedgerApproveTest < ActiveSupport::TestCase
  test "Approval" do
    lgroup = ledger_full_groups(:group_all)
#    lsubgroup = ledger_subgroups(:group_dogs)
    lpost = ledger_posts(:lpost_one)
    luser_group_moderator = ledger_users(:message_moderator_user)
    luser_group_moderator2 = ledger_users(:message_moderator2_user)
    luser_post_creator = lpost.creator
    luser_someone = ledger_users(:someone_user)

    # Make an unapproved link; someone else makes the link.
    link_group1 = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_someone)
    link_group1.save!
    assert_not(link_group1.approved_parent)
    assert_not(link_group1.approved_child)

    # Make a partially approved link; creator of post makes the link.
    link_group2 = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_post_creator)
    link_group2.save!
    assert_not(link_group2.approved_parent)
    assert(link_group2.approved_child) # Child is pre-approved.

    # Make a partially approved link; moderator of group makes the link.
    link_group3 = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_group_moderator)
    link_group3.save!
    assert(link_group3.approved_parent)
    assert_not(link_group3.approved_child)

    # A banned moderator shouldn't approve messages.
    link_group4 = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_group_moderator2)
    link_group4.save!
    assert_not(link_group4.approved_parent)
    assert_not(link_group4.approved_child)

    # Do approval by the group's moderator.

    # Approval in a subgroup.
  end
end
