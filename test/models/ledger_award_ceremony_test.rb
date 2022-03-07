# frozen_string_literal: true

require "test_helper"

class LedgerAwardCeremonyTest < ActiveSupport::TestCase
  test "Fading after Ceremony" do
    # See that the points of a Ledger object fade after an awards ceremony.
    # Have to clear the cached ceremony number since the test framework
    # sometimes leaves that global variable with an old value.
    LedgerAwardCeremony.clear_ceremony_cache
    ceremony_number = LedgerAwardCeremony.last_ceremony
    lpost = ledger_posts(:lpost_one)
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
    LedgerAwardCeremony.clear_ceremony_cache
    assert_equal(0, LedgerAwardCeremony.last_ceremony,
      "Should be no ceremonies in the database yet.")
    # Post 3 has two reply links giving it (up, meh, down):
    # Post four reply at Ceremony 1: (0, 0.2, 0)
    # Post five reply at Ceremony 2: (0.3, 0, 0)
    # Post 4 is a reply, has at ceremony 1: (0.7, 0, 0)
    # Post 5 is a reply, has at ceremony 2: (0, 0, 1.6)
    lpost3 = ledger_posts(:lpost_three)
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
    # in the replies.  Also do approvals, and test deletion effects on points.
    user_reader = ledger_users(:reader_user) # This user gets 10 points weekly.
    user_reader.user # Make sure corresponding user record exists.
    LedgerAwardCeremony.clear_ceremony_cache # Only needed when testing.
    LedgerAwardCeremony.start_ceremony
    assert_equal(1, LedgerAwardCeremony.last_ceremony,
      "Should just have one Ceremony in the test database at this point.")
    user_outsider = ledger_users(:outsider_user)
    lpost1 = LedgerPost.create!(creator: user_outsider,
      subject: "First Post", content: "The **Post** created by an outsider.")
    lpost2 = LedgerPost.create!(creator: user_reader,
      subject: "First Reply", content: "The first reply to the *Post*.")
    reply_1_2 = LinkReply.create!(creator: user_reader,
      original_post: lpost1, reply_post: lpost2,
      string1: "Link post 2 as a reply to 1.",
      rating_points_spent: 1.0,
      rating_points_boost_parent: 0.2, rating_direction_parent: "M",
      rating_points_boost_child: 0.7, rating_direction_child: "U")
    assert_equal(1, reply_1_2.original_ceremony)
    assert_in_delta(LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT -
      LedgerAwardCeremony::OBJECT_TRANSACTION_FEE,
      lpost1.current_meh_points, 0.0000001, "Not approved so unchanged")
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001, "Approved points")
    assert_in_delta(10 * LedgerAwardCeremony::FADE -
      LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT - # Created lpost2.
      1.0, # Created reply_1_2.
      user_reader.current_meh_points, 0.0000001, "Spent them")

    # Incremental update in the same ceremony week should do nothing.
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta(LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT -
      LedgerAwardCeremony::OBJECT_TRANSACTION_FEE,
      lpost1.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)

    # Try to approve the parent end of the link, should do nothing since we're
    # using the owner of the child end.
    marker = LedgerApprove.mark_records([reply_1_2], true, user_reader,
      "Testing incremental point recalculation.",
      "Turning on approval for wrong user, so reply approved.")
    assert_nil(marker, "Marking should do nothing, since changing nothing.")
    assert_in_delta(LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT -
      LedgerAwardCeremony::OBJECT_TRANSACTION_FEE,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.reload.current_up_points, 0.0000001)

    # Really approve the parent end of the link.
    marker = LedgerApprove.mark_records([reply_1_2], true, user_outsider,
      "Testing incremental point recalculation.",
      "Turning on approval of original post, does it turn on the points?")
    assert(marker, "Marking should do something this time.")
    assert_in_delta(LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT -
      LedgerAwardCeremony::OBJECT_TRANSACTION_FEE,
      lpost1.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)
    assert_in_delta(LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT -
      LedgerAwardCeremony::OBJECT_TRANSACTION_FEE + 0.2,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.reload.current_up_points, 0.0000001)

    # Delete the reply link, points should be affected.
    LedgerDelete.mark_records([reply_1_2], true, user_outsider,
      "Testing incremental point recalculation.",
      "Deleting the LinkReply, does it turn off the points?")
    assert_in_delta(0.0, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Turn off the approval of the child end of the link, while deleted.
    LedgerApprove.mark_records([reply_1_2], false, user_reader,
      "Testing incremental point recalculation.",
      "Unapproving the child end of the link while deleted.")
    assert_in_delta(0.0, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Undelete the reply link, points should be affected.
    LedgerDelete.mark_records([reply_1_2], false, user_outsider,
      "Testing incremental point recalculation.",
      "Undeleting the LinkReply, does it turn on the points?")
    assert_in_delta(0.2, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Do a Ceremony, then reapprove the child end of the link.
    LedgerAwardCeremony.start_ceremony
    lpost1.reload.update_current_points
    lpost2.reload.update_current_points
    assert_in_delta(0.2 * 0.97, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)
    LedgerApprove.mark_records([reply_1_2], true, user_reader,
      "Testing incremental point recalculation.",
      "Re-approving the child end of the link while undeleted.")
    assert_in_delta(0.2 * 0.97, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7 * 0.97, lpost2.reload.current_up_points, 0.0000001)

    # Recalculate the points from the beginning.
    lpost1.update_attribute(:current_ceremony, -1)
    lpost2.update_attribute(:current_ceremony, -1)
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta(0.2 * 0.97, lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7 * 0.97, lpost2.reload.current_up_points, 0.0000001)

    # Recalculate with a deletion in effect, and two more ceremonies.
    LedgerAwardCeremony.start_ceremony
    lpost1.update_attribute(:current_ceremony, -2)
    lpost2.update_attribute(:current_ceremony, -2)
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta(0.2 * 0.97 * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7 * 0.97 * 0.97,
      lpost2.reload.current_up_points, 0.0000001)

    # Unapprove the child end again, and update the ceremony too.
    LedgerApprove.mark_records([reply_1_2], false, user_reader,
      "Testing incremental point recalculation.",
      "Unapproving the child end of the link while not deleted.")
    LedgerAwardCeremony.start_ceremony
    lpost1.update_attribute(:current_ceremony, -3)
    lpost2.update_attribute(:current_ceremony, -3)
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta(0.2 * 0.97 * 0.97 * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)
  end
end
