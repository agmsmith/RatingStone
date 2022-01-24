# frozen_string_literal: true

require "test_helper"

class LinkBonusUniqueTest < ActiveSupport::TestCase
  test "Create when Duplicate Exists" do
    lpost = ledger_posts(:lpost_two)
    luser_reader = ledger_users(:reader_user)
    luser_outsider = ledger_users(:outsider_user)

    original_link = LinkBonus.new(bonus_points: 1, parent: lpost,
      child: luser_outsider, creator: luser_reader,
      approved_parent: true, approved_child: true)
    original_link.save!

    duplicate_link = LinkBonus.new(bonus_points: 2, parent: lpost,
      child: luser_outsider, creator: luser_outsider,
      approved_parent: true, approved_child: true)
    assert(duplicate_link.save,
      "Should successfully save a duplicate if uniqueness not required.")
    assert_empty(duplicate_link.errors[:validate_uniqueness])

    duplicate_link = LinkBonusUnique.new(bonus_points: 3, parent: lpost,
      child: luser_outsider, creator: luser_outsider,
      approved_parent: true, approved_child: true)
    assert_not(duplicate_link.save,
      "Should not save a duplicate when uniqueness is required.")
    assert_not_empty(duplicate_link.errors[:validate_uniqueness])

    single_unique_link = LinkBonusUnique.new(bonus_points: 4, parent: lpost,
      child: luser_reader, creator: luser_outsider,
      approved_parent: true, approved_child: true)
    assert(single_unique_link.save,
      "Should save successfully when it is unique.")
    assert_empty(single_unique_link.errors[:validate_uniqueness])
  end

  test "Undelete and Approve versus Uniqueness" do
    lpost = ledger_posts(:lpost_two)
    luser_reader = ledger_users(:reader_user)
    luser_outsider = ledger_users(:outsider_user)

    # Create the original link in a deleted state.
    original_link = LinkBonusUnique.new(bonus_points: 1, parent: lpost,
      child: luser_outsider, creator: luser_reader,
      deleted: true, approved_parent: true, approved_child: true)
    original_link.save!

    duplicate_link = LinkBonusUnique.new(bonus_points: 2, parent: lpost,
      child: luser_outsider, creator: luser_reader,
      approved_parent: true, approved_child: true)
    assert(duplicate_link.save)

    # Try undeleting the original link, should fail.
    assert_raise(RatingStoneErrors) do
      LedgerDelete.mark_records([original_link], false, luser_reader)
    end

    # Un-approve the duplicate.
    LedgerApprove.mark_records([duplicate_link], false, luser_outsider)

    # Now should be able to undelete the original.
    undelete_record = LedgerDelete.mark_records([original_link], false,
      luser_reader)
    assert_equal(undelete_record.class.name, "LedgerDelete")
  end
end
