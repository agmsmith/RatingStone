# frozen_string_literal: true

require 'test_helper'

class LedgerDeleteTest < ActiveSupport::TestCase
  test "deleting records" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String One")
    original_lbase.save!
    amended_lbase = original_lbase.append_version
    amended_lbase.string1 = "An Amended string."
    amended_lbase.save!
    original_lbase.reload # Has been amended.
    amended_lbase = original_lbase.append_version
    amended_lbase.string1 = "The string changed a second time."
    amended_lbase.save!
    second_lbase = LedgerPost.new(creator_id: 0, subject: "Second Test",
      content: "A second LedgerBase record, actually a post.")
    second_lbase.save!
    link_original_second = LinkBase.new(creator_id: 0, parent: original_lbase,
      child: second_lbase, rating_points_spent: 1,
      rating_points_boost_child: 0.5, rating_points_boost_parent: 0.25,
      rating_direction: 'U')
    link_original_second.save!
    original_lbase.reload

    # Note that no matter what version of a record we ask to delete, only the
    # original version gets an AuxLedger record saying it was deleted and the
    # other versions just have their deleted flag set.

    records_to_delete = [amended_lbase, second_lbase, link_original_second]
    assert_equal(records_to_delete.size, 3)
    all_deleted_records = original_lbase.all_versions.to_a
    all_deleted_records.push(second_lbase, link_original_second)
    all_deleted_records.each do |x|
      assert_not(x.deleted)
      x.reload
      assert_not(x.deleted)
    end
    ledger_delete = LedgerDelete.delete_records(records_to_delete,
      LedgerUser.first, "Some Context", "Testing deletion.")
    assert_equal(ledger_delete.reason, "Testing deletion.")
    assert_equal(ledger_delete.context, "Some Context")
    all_deleted_records.each do |x|
      x.reload
      assert(x.deleted)
    end
    # Check that the right auxiliary records were created.
    deleted_ledgers = ledger_delete.aux_ledger_descendants
    assert_equal(deleted_ledgers.count, 2)
    assert(deleted_ledgers.include?(original_lbase))
    assert(deleted_ledgers.include?(second_lbase))
    deleted_links = ledger_delete.aux_link_descendants
    assert_equal(deleted_links.count, 1)
    assert(deleted_links.include?(link_original_second))

    # Testing the search for who deleted me functionality.

    all_deleted_records.each do |x|
      deleted_by_records = x.deleted_by
      assert_equal(deleted_by_records.count, 1)
      assert(deleted_by_records.include?(ledger_delete))
    end
    assert_equal(ledger_delete.deleted_by.count, 0)

    # Testing the undelete functionality.

    records_to_undelete = [amended_lbase, link_original_second]
    all_undeleted_records = original_lbase.all_versions.to_a
    all_undeleted_records.push(link_original_second)
    ledger_undelete = LedgerUndelete.undelete_records(records_to_undelete,
      LedgerUser.first, "Some Other Context", "Testing undeletion.")
    assert_equal(ledger_undelete.reason, "Testing undeletion.")
    all_undeleted_records.each do |x|
      x.reload
      assert(!x.deleted)
    end
    # One we didn't undelete should still be deleted.
    second_lbase.reload
    assert(second_lbase.deleted)
    # Check that the right auxiliary records were created.
    undeleted_ledgers = ledger_undelete.aux_ledger_descendants
    assert_equal(undeleted_ledgers.count, 1)
    assert(undeleted_ledgers.include?(original_lbase))
    undeleted_links = ledger_undelete.aux_link_descendants
    assert_equal(undeleted_links.count, 1)
    assert(undeleted_links.include?(link_original_second))

    # Testing the search for who undeleted me.

    all_undeleted_records.each do |x|
      undeleted_by_records = x.deleted_by
      assert_equal(undeleted_by_records.count, 2)
      assert(undeleted_by_records.include?(ledger_delete))
      assert(undeleted_by_records.include?(ledger_undelete))
      assert_equal(undeleted_by_records.first, ledger_undelete)
    end
    assert_equal(ledger_undelete.deleted_by.count, 0)
  end

  # Test permission to delete.  Need to be creator or an owner to delete.

  test "delete needs permission" do
    assert_raise(RatingStoneErrors) do
      LedgerDelete.delete_records([ledger_posts(:lpost_one)],
        ledger_users(:member_user), "Testing delete from wrong user.")
    end
    assert_raise(RatingStoneErrors) do
      LedgerUndelete.undelete_records([ledger_posts(:lpost_one)],
        ledger_users(:member_user), "Testing undelete on someone else's thing.")
    end
    ldelete = LedgerDelete.delete_records([ledger_posts(:lpost_two)],
      ledger_users(:member_user), "My Context",
      "Testing delete by creator, should work.")
    assert_equal(ldelete.class.name, "LedgerDelete")
    assert_equal("Testing delete by creator, should work.", ldelete.reason)
    assert_equal("My Context", ldelete.context)
    lundelete = LedgerUndelete.undelete_records([ledger_posts(:lpost_two)],
      ledger_users(:outsider_user), "That Context",
      "Testing undelete by owner, should work.")
    assert_equal(lundelete.class.name, "LedgerUndelete")
    assert_equal("Testing delete by creator, should work.", ldelete.reason)
    ldelete = LedgerDelete.delete_records([ledger_posts(:lpost_two)],
      ledger_users(:outsider_user),
      "Testing delete by owner (not creator), should work.")
    assert_equal(ldelete.class.name, "LedgerDelete")
  end

  # Test permission to delete for special kinds of links.

  test "delete permission for special links" do
    # A normal one without extra people, though parent is a group.
    link = link_subgroups(:linkgroup_all_animals)
    assert_raise(RatingStoneErrors) do
      LedgerDelete.delete_records([link], ledger_users(:group_creator_user))
    end
    assert_not(link.deleted)
    luser = link.creator.append_version # Testing with a later version id.
    luser.name = "Later #{link.creator.name}"
    luser.save!
    assert_equal(LedgerDelete.delete_records([link], luser).class.name,
      "LedgerDelete")
    link.reload
    assert(link.deleted)

    # Linking a post to a group lets group moderators and the post owner also
    # delete the link, as well as the usual link creator.
    link = link_group_contents(:group_dogs_content_post2)
    assert_raise(RatingStoneErrors) do
      LedgerDelete.delete_records([link], ledger_users(:undesirable_user))
    end
    assert_not(link.deleted)
    luser = ledger_posts(:lpost_two).creator.latest_version
    assert_not_equal(luser.original_version_id, link.creator_id)
    assert_equal("LedgerDelete",
      LedgerDelete.delete_records([link], luser).class.name)
    link.reload
    assert(link.deleted)
    luser = ledger_users(:message_moderator_user)
    assert_not_equal(luser.original_version_id, link.creator_id)
    assert_equal("LedgerUndelete",
      LedgerUndelete.undelete_records([link], luser).class.name)
    link.reload
    assert_not(link.deleted)
  end
end
