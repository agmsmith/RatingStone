# frozen_string_literal: true

require 'test_helper'

class LinkBaseTest < ActiveSupport::TestCase
  test "Automatic Approval" do
    lgroup = ledger_full_groups(:group_all)
    lpost = ledger_posts(:lpost_one)
    luser_group_creator = ledger_users(:group_creator_user)
    luser_group_owner = ledger_users(:group_owner_user)
    luser_post_creator = lpost.creator.latest_version
    luser_outsider = ledger_users(:outsider_user)

    # See if creator of parent is approved.
    link_group_content = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_group_creator)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    link_group_content.save!
    assert(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)

    # See if owner of parent is approved.
    link_group_content = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_group_owner)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    link_group_content.save!
    assert(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)

    # See if unrelated to parent is not approved, and child owner is.
    link_group_content = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_post_creator)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    link_group_content.save!
    assert_not(link_group_content.approved_parent)
    assert(link_group_content.approved_child)

    # Should cause a validation error if saving a non-original version.
    lpost2 = lpost.append_version
    lpost2.content = "This is an edited post."
    lpost2.save!
    lpost.reload # Has been amended.
    link_group_content = LinkGroupContent.new(parent: lgroup, child: lpost2,
      creator: luser_post_creator)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    assert_not(link_group_content.valid?)
    assert_equal("Child isn't the original version: ##{lpost2.id} " \
      "[#{lpost.id}-#{lpost2.id}] LedgerPost " \
      "(First Fixture Subject, by: #0 Fixture created R...)",
      link_group_content.errors[:unoriginal_child].first)

    # Should be able to change the creator of the object in a later version,
    # and have tests use that new creator.
    lpost3 = lpost.append_version
    lpost3.content = "This post has a new creator."
    lpost3.creator = luser_outsider
    lpost3.save!
    lpost.reload # Has been amended.

    link_group_content = LinkGroupContent.new(parent: lgroup,
      child: lpost3.original_version, creator: luser_outsider)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    link_group_content.save!
    assert_not(link_group_content.approved_parent)
    assert(link_group_content.approved_child)

    link_group_content = LinkGroupContent.new(parent: lgroup, child: lpost,
      creator: luser_post_creator)
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    link_group_content.save!
    assert_not(link_group_content.approved_parent)
    assert_not(link_group_content.approved_child)
    # Usually don't modify link records, but check that approvals don't change
    # if we change the creator of a link.  Should only be set for new records.
    link_group_content.creator = luser_outsider
    link_group_content.save!
    assert_not(link_group_content.approved_child)
  end
end
