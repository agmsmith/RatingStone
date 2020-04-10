# frozen_string_literal: true

require 'test_helper'

class LedgerBaseTest < ActiveSupport::TestCase
  def setup
    # Create the root user/object #0.
    Rails.application.load_seed
  end

  test "original record fields" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String One")
    assert_nil(original_lbase.id, "No ID number before saving")
    assert(original_lbase.save, "Save should succeed.")
    assert_not_nil(original_lbase.id, "Has an ID number after saving")
    assert_equal(original_lbase.id, original_lbase.original_id,
      "original_id of the original record should be the same as its ID number")
  end

  test "amended record fields" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "Some String One")
    original_lbase.deleted = true
    original_lbase.current_down_points = 1
    original_lbase.current_meh_points = 2
    original_lbase.current_up_points = 3
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
end
