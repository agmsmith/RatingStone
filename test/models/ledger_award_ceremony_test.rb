# frozen_string_literal: true

require "test_helper"

class LedgerAwardCeremonyTest < ActiveSupport::TestCase
  test "Fading after Ceremony" do
    lpost = ledger_posts(:lpost_one)

    # See that the points of a Ledger object fade after an awards ceremony.
    ceremony_number = LedgerAwardCeremony.last_ceremony
    lpost.update_current_points
    lpost.current_down_points = 1.1
    lpost.current_meh_points = 2.2
    lpost.current_up_points = 3.3
    lpost.save!
    LedgerAwardCeremony.start_ceremony
    LedgerAwardCeremony.start_ceremony
    assert_equal(ceremony_number + 2, LedgerAwardCeremony.last_ceremony)
    assert_equal(1.1, lpost.current_down_points)
    lpost.update_current_points
    assert(1.1 * 0.97 * 0.97, lpost.current_down_points)
    assert(2.2 * 0.97 * 0.97, lpost.current_meh_points)
    assert(3.3 * 0.97 * 0.97, lpost.current_up_points)
    assert_equal(ceremony_number + 2, lpost.current_ceremony)
  end
end
