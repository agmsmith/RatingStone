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
    records_to_delete = original_lbase.all_versions.to_a
      .append(second_lbase, link_original_second)
    assert_equal(records_to_delete.size, 5)
    records_to_delete.each do |x|
      assert_not(x.deleted)
    end
    ledger_delete = LedgerDelete.delete_records(records_to_delete,
      LedgerUser.first, "Testing deletion.")
    assert_equal(ledger_delete.reason, "Testing deletion.")
    records_to_delete.each do |x|
      x.reload
      assert(x.deleted)
    end
    deleted_ledgers = ledger_delete.aux_ledger_descendants
    assert_equal(deleted_ledgers.count, 4)
    deleted_ledgers.each do |x|
      assert(records_to_delete.include?(x))
    end
    deleted_links = ledger_delete.aux_link_descendants
    assert_equal(deleted_links.count, 1)
    deleted_links.each do |x|
      assert(records_to_delete.include?(x))
    end
  end
end
