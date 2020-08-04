# frozen_string_literal: true

require 'test_helper'

class LedgerApproveTest < ActiveSupport::TestCase
  test "Approval" do
    lgroup = ledger_full_groups(:group_all)
    lsubgroup = ledger_subgroups(:group_dogs)
    lpost = ledger_posts(:lpost_one)
    luser_group_moderator = ledger_users(:message_moderator_user)
    luser_group_moderator2 = ledger_users(:message_moderator2_user)
    luser_post_creator = lpost.creator
    luser_outsider = ledger_users(:outsider_user)

    # Make an unapproved link; someone else unrelated makes the link.
    link_group1 = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_outsider)
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

    # Do manual approval by the group's banned moderator.
    assert_not(link_group2.approved_parent)
    assert_raise(RatingStoneErrors) do
      LedgerApprove.approve_records([link_group2],
        luser_group_moderator2, "Testing approvals",
        "Banned moderator trying to approve something.")
    end

    # Do manual approval by the group's regular moderator.
    assert_not(link_group2.approved_parent)
    ledger_approve = LedgerApprove.approve_records([link_group2],
      luser_group_moderator, "Testing approvals",
      "Regular moderator trying to approve something.")
    assert(ledger_approve)

    # Check that the right auxiliary records were created.
    approved_links = ledger_approve.aux_link_downs
    assert_equal(approved_links.count, 1)
    assert(approved_links.first.parent == ledger_approve)
    assert(approved_links.first.child == link_group2)

    # Approval in a subgroup.
    lpost2 = LedgerPost.new(creator: luser_outsider,
      content: "This is a subgroup post.")
    lpost2.save!
    link_group5 = LinkGroupContent.new(parent: lsubgroup, child: lpost2,
      creator: luser_outsider)
    link_group5.save!
    assert_not(link_group5.approved_parent)
    assert(link_group5.approved_child)

    # Manual approval of a linked post in a subgroup.
    ledger_approve = LedgerApprove.approve_records([link_group5],
      luser_group_moderator, "Testing approvals",
      "Regular moderator trying to approve a subgroup post.")
    assert(ledger_approve)
    assert(link_group5.approved_parent)

    # Approval in multiple groups.
  end
end
