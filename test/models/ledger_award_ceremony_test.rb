# frozen_string_literal: true

require "test_helper"

class LedgerAwardCeremonyTest < ActiveSupport::TestCase
  test "Fading after Ceremony" do
    # See that the points of a Ledger object fade after an awards ceremony.
    # Have to clear the cached ceremony number since the test framework
    # sometimes leaves that global variable with an old value.
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
    lpost3.request_full_point_recalculation
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
    user_reader = ledger_users(:reader_user) # This user gets 10 points weekly,
    # and starts with 10 extra meh points, which will vanish when recalculated.
    user_reader.user # Make sure corresponding user record exists.
    LedgerAwardCeremony.start_ceremony
    assert_equal(1, LedgerAwardCeremony.last_ceremony,
      "Should just have one Ceremony in the test database at this point.")
    user_outsider = ledger_users(:outsider_user)
    user_outsider.user # Make sure corresponding user record exists.
    lpost1 = LedgerPost.create!(creator: user_outsider,
      subject: "First Post", content: "The **Post** created by an outsider.")
    lpost2 = LedgerPost.create!(creator: user_reader,
      subject: "First Reply", content: "The first reply to the *Post*.")
    reply_1_2 = LinkReply.create!(creator: user_reader,
      prior_post: lpost1, reply_post: lpost2,
      string1: "Link post 2 as a reply to 1.",
      rating_points_spent: 1.0,
      rating_points_boost_parent: 0.2, rating_direction_parent: "M",
      rating_points_boost_child: 0.7, rating_direction_child: "U")
    assert_equal(1, reply_1_2.original_ceremony)
    default_object_boost = LedgerBase::DEFAULT_SPEND_FOR_OBJECT *
      (1.0 - LedgerBase::OBJECT_TRANSACTION_FEE_RATE)
    assert_in_delta(default_object_boost, lpost1.current_meh_points, 0.0000001,
      "Not approved so unchanged")
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001, "Approved points")
    assert_in_delta(10 * LedgerAwardCeremony::FADE - # Initial 10 points, faded.
      LedgerBase::DEFAULT_SPEND_FOR_OBJECT - # Created lpost2.
      1.0, # Created reply_1_2 by spending 1.0 points.
      user_reader.current_meh_points, 0.0000001, "User should have spent this")

    # Incremental update in the same ceremony week should do nothing.
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta(default_object_boost, lpost1.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)

    # Try to approve the parent end of the link, should do nothing since we're
    # using the owner of the child end.
    marker = LedgerApprove.mark_records([reply_1_2], true, user_reader,
      "Testing incremental point recalculation.",
      "Turning on approval for wrong user, so reply approved.")
    assert_nil(marker, "Marking should do nothing, since changing nothing.")
    assert_in_delta(default_object_boost, lpost1.reload.current_meh_points,
      0.0000001)
    assert_in_delta(0.7, lpost2.reload.current_up_points, 0.0000001)

    # Really approve the parent end of the link.
    marker = LedgerApprove.mark_records([reply_1_2], true, user_outsider,
      "Testing incremental point recalculation.",
      "Turning on approval of original post, does it turn on the points?")
    assert(marker, "Marking should do something this time.")
    lpost1.reload
    lpost2.reload
    assert_in_delta(default_object_boost +
      0.2, # 0.2 from the approved LinkReply parent end.
      lpost1.current_meh_points, 0.0000001)
    assert_in_delta(0.7, lpost2.current_up_points, 0.0000001)
    assert_in_delta(default_object_boost, lpost2.current_meh_points, 0.0000001)

    # Delete the reply link, points should be affected.
    LedgerDelete.mark_records([reply_1_2], true, user_outsider,
      "Testing incremental point recalculation.",
      "Deleting the LinkReply, does it turn off the points?")
    assert_in_delta(default_object_boost, lpost1.reload.current_meh_points,
      0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Turn off the approval of the child end of the link, while deleted.
    LedgerApprove.mark_records([reply_1_2], false, user_reader,
      "Testing incremental point recalculation.",
      "Unapproving the child end of the link while deleted.")
    assert_in_delta(default_object_boost, lpost1.reload.current_meh_points,
      0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Undelete the reply link, points should be affected.
    LedgerDelete.mark_records([reply_1_2], false, user_outsider,
      "Testing incremental point recalculation.",
      "Undeleting the LinkReply, does it turn on the points?")
    assert_in_delta(default_object_boost +
      0.2, # 0.2 from the approved LinkReply parent end.
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Do a Ceremony, then reapprove the child end of the link.
    LedgerAwardCeremony.start_ceremony
    lpost1.reload.update_current_points
    lpost2.reload.update_current_points
    assert_in_delta((default_object_boost + 0.2) * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)
    LedgerApprove.mark_records([reply_1_2], true, user_reader,
      "Testing incremental point recalculation.",
      "Re-approving the child end of the link while undeleted.")
    assert_in_delta((default_object_boost + 0.2) * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7 * 0.97, lpost2.reload.current_up_points, 0.0000001)

    # Recalculate the points from the beginning.
    lpost1.update_attribute(:current_ceremony, -1)
    lpost2.update_attribute(:current_ceremony, -1)
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta((default_object_boost + 0.2) * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.7 * 0.97, lpost2.reload.current_up_points, 0.0000001)

    # Recalculate with another ceremony.
    LedgerAwardCeremony.start_ceremony
    lpost1.request_full_point_recalculation
    lpost2.request_full_point_recalculation
    lpost1.update_current_points
    lpost2.update_current_points
    assert_in_delta((default_object_boost + 0.2) * 0.97 * 0.97,
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
    assert_in_delta((default_object_boost + 0.2) * 0.97 * 0.97 * 0.97,
      lpost1.reload.current_meh_points, 0.0000001)
    assert_in_delta(0.0, lpost2.reload.current_up_points, 0.0000001)

    # Check that the points spent and gained by user_reader are correct.
    # History:
    # Starts with 10 meh points, from YML fixture test data, will disappear later.
    # Ceremony #1, +0 points (bonus starts after ceremony #1), 10 fades to 9.7
    # Create lpost2, 0.5 points.
    # Create reply link, 1.0 points, 0.2 boost parent.
    # Failed LedgerApprove, 0 points.
    # Create LedgerApprove/false, 0.5 points.
    # Ceremony #2, +10 points.
    # Create LedgerApprove/true, 0.5 points.
    # Ceremony #3, +10 points.
    # Create LedgerApprove/false, 0.5 points.
    # Ceremony #4, +10 points.
    user_reader.update_current_points
    expected_points = ((((10 * 0.97) -
      0.5 - 1.0 - 0.5) * 0.97 + 10.0 -
      0.5) * 0.97 + 10.0 -
      0.5) * 0.97 + 10
    assert_in_delta(expected_points, user_reader.current_meh_points, 0.0000001)

    user_reader.request_full_point_recalculation
    user_reader.update_current_points
    expected_points = ((((0 * 0.97) - # It is actually zero points initially.
      0.5 - 1.0 - 0.5) * 0.97 + 10.0 -
      0.5) * 0.97 + 10.0 -
      0.5) * 0.97 + 10
    assert_in_delta(expected_points, user_reader.current_meh_points, 0.0000001)
  end

  test "Expiry Times" do
    # Check that the expiry time is sensible.  Should be when the total number
    # of points (all categories) assigned to an object fade away to 0.01.
    lpost = ledger_posts(:lpost_bonus10) # This one has 10 points upon creation.
    lpost.update_current_points
    assert_in_delta(10.0, lpost.current_meh_points, 0.0000001)
    assert_in_delta(Time.now +
      LedgerAwardCeremony::DAYS_PER_CEREMONY.days *
      (Math.log(LedgerAwardCeremony::FADED_TO_NOTHING /
      lpost.current_meh_points) / LedgerAwardCeremony::FADE_LOG).ceil,
      lpost.expiry_time, 1.0)
    generations = (Math.log(LedgerAwardCeremony::FADED_TO_NOTHING /
      lpost.current_meh_points) / LedgerAwardCeremony::FADE_LOG).ceil
    assert(generations > 100, "Should take many generations to fade away.")
    assert_in_delta(lpost.current_meh_points *
      LedgerAwardCeremony::FADE**generations, 0.01, 0.0001,
      "Should have faded to just below 0.01 after that many generations.")
    assert_in_delta(lpost.expiry_time - Time.now,
      LedgerAwardCeremony::DAYS_PER_CEREMONY.days *
      generations, 3600, "Time should correspond to generations, within " \
        " an hour due to time zone glitches.")
    LedgerAwardCeremony.start_ceremony
    lpost.update_current_points
    assert_in_delta(Time.now +
      LedgerAwardCeremony::DAYS_PER_CEREMONY.days *
      (Math.log(LedgerAwardCeremony::FADED_TO_NOTHING /
      lpost.current_meh_points) / LedgerAwardCeremony::FADE_LOG).ceil,
      lpost.expiry_time, 1.0)
    LedgerAwardCeremony.start_ceremony
    lpost.update_current_points
    assert_in_delta(Time.now +
      LedgerAwardCeremony::DAYS_PER_CEREMONY.days *
      (Math.log(LedgerAwardCeremony::FADED_TO_NOTHING /
      lpost.current_meh_points) / LedgerAwardCeremony::FADE_LOG).ceil,
      lpost.expiry_time, 1.0)
  end
end
