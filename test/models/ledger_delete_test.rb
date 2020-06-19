# frozen_string_literal: true

require 'test_helper'

class LedgerDeleteTest < ActiveSupport::TestCase
  test "deleting records" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String One")
    original_lbase.save
    amended_lbase = original_lbase.append_ledger
    amended_lbase.string1 = "An Amended string."
    amended_lbase.save
    amended_lbase = original_lbase.append_ledger
    amended_lbase.string1 = "The string changed a second time."
    amended_lbase.save
    second_lbase = LedgerPost.new(creator_id: 0,
      content: "A second LedgerBase record, actually a post.")
    second_lbase.save
    link_original_second = LinkBase.new(creator_id: 0, parent: original_lbase,
      child: second_lbase, rating_points_spent: 1,
      rating_points_boost_child: 0.5, rating_points_boost_parent: 0.25,
      rating_direction: 'U')
    link_original_second.save
    original_lbase.reload

    # Note that no matter what record we ask to delete, only the original
    # version gets deleted and the other versions just have their deleted flag
    # set.

    records_to_delete = [amended_lbase, second_lbase, link_original_second]
    assert_equal(records_to_delete.size, 3)
    all_deleted_records = original_lbase.all_versions.to_a
    all_deleted_records.push(second_lbase, link_original_second)
    all_deleted_records.each do |x|
      assert_not(x.deleted)
    end
    ledger_delete = LedgerDelete.delete_records(records_to_delete,
      LedgerUser.first, "Testing deletion.")
    assert_equal(ledger_delete.reason, "Testing deletion.")
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
      LedgerUser.first, "Testing undeletion.")
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

  test "delete authorisation" do
    lbase = LedgerBase.new(creator: users(:archer).ledger_user,
      string1: "Something to delete, by Archer.")
    lbase.save
    assert_nil(LedgerDelete.delete_records([lbase],
      users(:malory).ledger_user, "Testing delete from wrong user."))
    assert_nil(LedgerUndelete.undelete_records([lbase],
      users(:archer).ledger_user, "Testing undelete on not deleted thing."))
    ldelete = LedgerDelete.undelete_records([lbase], users(:archer).ledger_user,
      "Testing delete, should work.")
    assert_equal(:LedgerDelete, ldelete.class)
    assert_equal("Testing delete, should work.", ldelete.reason)
  end
end
