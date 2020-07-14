# frozen_string_literal: true

require 'test_helper'

class LedgerBaseTest < ActiveSupport::TestCase
  test "original record fields" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String One")
    assert_nil(original_lbase.id, "No ID number before saving")
    assert(original_lbase.save, "Save should succeed.")
    assert_not_nil(original_lbase.id, "Has an ID number after saving")
    assert_equal(original_lbase.id, original_lbase.original_id,
      "original_id of the original record should be the same as its ID number")
  end

  test "creator always required" do
    assert_raise(ActiveRecord::NotNullViolation, "Can't have a NULL creator") do
      lbase = LedgerBase.new(creator_id: nil, string1: "String Two")
      lbase.save
    end
    assert_raise(ActiveRecord::InvalidForeignKey, "Creator must exist") do
      lbase = LedgerBase.new(creator_id: 123456, string1: "String Three")
      lbase.save
    end
  end

  test "creator must be original version" do
    later_creator = ledger_users(:someone_user).append_ledger
    later_creator.email = "SomeLaterVersion@Somewhere.com"
    assert(later_creator.save)
    lbase = LedgerBase.new(creator: later_creator, string1: "Just One")
    assert_not(lbase.save)
    assert_equal(lbase.errors[:unoriginal_creator].first,
      "Creator LedgerUser ##{later_creator.id} isn't the original version.")
  end

  test "amended record fields" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String Four")
    original_lbase.deleted = true
    original_lbase.current_down_points = 1.0
    original_lbase.current_meh_points = 2.0
    original_lbase.current_up_points = 3.0
    original_lbase.save
    assert_equal(original_lbase.latest_version.id, original_lbase.id)
    amended_lbase = original_lbase.append_ledger
    # Nothing should change in the original record until saved.
    assert_nil(original_lbase.amended_id)
    assert_equal(original_lbase.id, original_lbase.original_id)
    amended_lbase.string1 = "An Amended string."
    assert(amended_lbase.save)
    original_lbase.reload
    # After save, the amended and original references should update.
    assert_equal(original_lbase.id, amended_lbase.original_id)
    assert_equal(original_lbase.amended_id, amended_lbase.id)
    assert_nil(amended_lbase.amended_id)
    assert_equal(original_lbase.latest_version.id, amended_lbase.id)
    assert_not(amended_lbase.deleted)
    assert_equal(amended_lbase.current_down_points, 0.0)
    assert_equal(amended_lbase.current_meh_points, 0.0)
    assert_equal(amended_lbase.current_up_points, 0.0)
    # After another amend.
    original_lbase.deleted = false
    original_lbase.save
    another_amend_lbase = original_lbase.append_ledger
    assert_equal(another_amend_lbase.string1, "An Amended string.")
    another_amend_lbase.string1 = "Amended a second time."
    another_amend_lbase.save
    original_lbase.reload
    assert_equal(original_lbase.id, another_amend_lbase.original_id)
    assert_equal(original_lbase.amended_id, another_amend_lbase.id)
    assert_nil(another_amend_lbase.amended_id)
    assert_not(another_amend_lbase.deleted)
    assert_equal(original_lbase.latest_version.id, another_amend_lbase.id)
    assert_equal(original_lbase.id, another_amend_lbase.original_version.id)
  end

  test "creator_owner? function" do
    lgroup = ledger_full_groups(:group_all)
    assert lgroup.creator_owner?(ledger_users(:group_creator_user))
    assert lgroup.creator_owner?(ledger_users(:group_owner_user))
    assert_not lgroup.creator_owner?(ledger_users(:message_moderator_user))
    assert_not lgroup.creator_owner?(ledger_users(:member_moderator_user))
    assert_not lgroup.creator_owner?(ledger_users(:member_user))
    assert_not lgroup.creator_owner?(ledger_users(:someone_user))
    assert_not lgroup.creator_owner?(ledger_users(:root_ledger_user))
    assert_raise(RatingStoneErrors, "Passing in a Post, not LedgerUser") do
      lgroup.creator_owner?(ledger_posts(:lpost_one))
    end
    assert_raise(RatingStoneErrors, "Passing in nil instead of LedgerUser") do
      lgroup.creator_owner?(nil)
    end
  end
end
