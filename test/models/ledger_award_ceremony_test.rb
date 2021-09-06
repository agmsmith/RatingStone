# frozen_string_literal: true

require "test_helper"

class LedgerAwardCeremonyTest < ActiveSupport::TestCase
  test "Fading after Ceremony" do
    lpost = ledger_posts(:lpost_one)

    # See that the points of a Ledger object fade after an awards ceremony.
    ceremony_number = LedgerAwardCeremony.last_ceremony
    lpost.update_current_points
    lpost.current_up_points = 3.3
    lpost.current_meh_points = 2.2
    lpost.current_down_points = 1.1
    lpost.save!
    LedgerAwardCeremony.start_ceremony
    LedgerAwardCeremony.start_ceremony
    assert_equal(ceremony_number + 2, LedgerAwardCeremony.last_ceremony)
    assert_equal(1.1, lpost.current_down_points)
    lpost.update_current_points
    assert_in_delta(3.3 * 0.97 * 0.97, lpost.current_up_points, 0.0000001)
    assert_in_delta(2.2 * 0.97 * 0.97, lpost.current_meh_points, 0.0000001)
    assert_in_delta(1.1 * 0.97 * 0.97, lpost.current_down_points, 0.0000001)
    assert_equal(ceremony_number + 2, lpost.current_ceremony)
  end

  test "Forced Recalculation of Rating Points" do
    # Post 3 has two reply links giving it (up, meh, down):
    # Post four reply at Ceremony 1: (0, 0.2, 0)
    # Post five reply at Ceremony 2: (0.3, 0, 0)
    # Post 4 is a reply, has at ceremony 1: (0.7, 0, 0)
    # Post 5 is a reply, has at ceremony 2: (0, 0, 1.6)
    lpost3 = ledger_posts(:lpost_three)
    assert_equal(0, LedgerAwardCeremony.last_ceremony) # No ceremonies yet.
    assert_equal(0, lpost3.original_ceremony)
    assert_equal(-1, lpost3.current_ceremony)
    lpost3.update_current_points
    assert_equal(0, lpost3.current_ceremony)
    # Links in future ceremonies shouldn't be included.
    assert_in_delta(0.0, lpost3.current_up_points, 0.0000001)
    assert_in_delta(0.0, lpost3.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost3.current_down_points, 0.0000001)

    # Do a ceremony.  Should include the ceremony 1 link's points, but not 2.
    LedgerAwardCeremony.start_ceremony
    assert_equal(1, LedgerAwardCeremony.last_ceremony)
    lpost3.current_ceremony = -1
    lpost3.save!
    lpost3.update_current_points
    assert_equal(1, lpost3.current_ceremony)
    assert_in_delta(0.0, lpost3.current_up_points, 0.0000001)
    assert_in_delta(0.2, lpost3.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost3.current_down_points, 0.0000001)

    # Do a ceremony.  Should include the ceremony 2 link's points now.
    LedgerAwardCeremony.start_ceremony
    assert_equal(2, LedgerAwardCeremony.last_ceremony)
    lpost3.current_ceremony = -1
    lpost3.save!
    lpost3.update_current_points
    assert_equal(2, lpost3.current_ceremony)
    assert_in_delta(0.3, lpost3.current_up_points, 0.0000001)
    assert_in_delta(0.2 * 0.97, lpost3.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost3.current_down_points, 0.0000001)

    # Do a ceremony, things should fade.
    LedgerAwardCeremony.start_ceremony
    assert_equal(3, LedgerAwardCeremony.last_ceremony)
    lpost3.current_ceremony = -1
    lpost3.save!
    lpost3.update_current_points
    assert_equal(3, lpost3.current_ceremony)
    assert_in_delta(0.3 * 0.97, lpost3.current_up_points, 0.0000001)
    assert_in_delta(0.2 * 0.97 * 0.97, lpost3.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost3.current_down_points, 0.0000001)

    # Check the reply posts, they have faded too.
    lpost4 = ledger_posts(:lpost_four)
    lpost4.update_current_points
    assert_equal(3, lpost4.current_ceremony)
    assert_in_delta(0.7 * 0.97 * 0.97, lpost4.current_up_points, 0.0000001)
    assert_in_delta(0.0, lpost4.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost4.current_down_points, 0.0000001)
    lpost5 = ledger_posts(:lpost_five)
    lpost5.update_current_points
    assert_equal(3, lpost5.current_ceremony)
    assert_in_delta(0.0, lpost5.current_up_points, 0.0000001)
    assert_in_delta(0.0, lpost5.current_meh_points, 0.0000001)
    assert_in_delta(1.6 * 0.97, lpost5.current_down_points, 0.0000001)
  end

  test "Incremental Recalculation of Rating Points" do
    # Make a post, and add reply posts over time, with points spent to link
    # in the replies.
    LedgerAwardCeremony.start_ceremony
    assert_equal(1, LedgerAwardCeremony.last_ceremony)
    lpost1 = LedgerPost.create!(creator: ledger_users(:outsider_user),
      subject: "First Post", content: "The **Post** created by an outsider.")
    lpost2 = LedgerPost.create!(creator: ledger_users(:member_user),
      subject: "First Reply", content: "The first reply to the *Post*.")
    reply_1_2 = LinkReply.create!(creator: ledger_users(:member_user),
      parent: lpost1, child: lpost2, string1: 'Link post 2 as a reply to 1.',
      rating_points_spent: 1.0,
      rating_points_boost_parent: 0.2, rating_direction_parent: "M",
      rating_points_boost_child: 0.7, rating_direction_child: "U")
    assert_equal(1, reply_1_2.original_ceremony)
    assert_in_delta(0.0, lpost1.current_down_points, 0.0000001)
    assert_in_delta(0.0, lpost1.current_meh_points, 0.0000001)
    lpost1.update_current_points
    assert_in_delta(0.0, lpost1.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)
    lpost2.update_current_points
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)

      # test approval changes, initially parent not approved.
      # Test time lapse, multiple ceremonies between incremental updates.
  end
end
