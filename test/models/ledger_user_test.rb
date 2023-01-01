# frozen_string_literal: true

require "test_helper"

class LedgerUserTest < ActiveSupport::TestCase
  def setup
    # Create the root user/object and sysop user.  Not needed, done as fixtures.
    # Rails.application.load_seed
  end

  test "Root user zero should exist" do
    root_luser = LedgerUser.find_by(id: 0) # Not find() so nil result allowed.
    assert_not_nil(root_luser, "Root ledger user should exist at id #0")
    assert_match(/root/i, root_luser.string1,
      "Root user should have Root in their name")
    assert_equal(root_luser.creator_id, 0,
      "Root user should be created by id #0 (itself)")
  end

  test "Create a regular Ledger User" do
    user = User.create!(
      name:  "Test Regular User",
      email: "SomeEMail@SomeDomain.com",
      password: "SomePassword",
      password_confirmation: "SomePassword",
    )
    user.activate
    luser = user.create_or_get_ledger_user
    assert_equal(luser.id, user.ledger_user_id, "LedgerUser should be in User")
    assert_equal(luser.id, luser.creator_id, "Users should be created by self")
    assert(luser.creator_owner?(luser), "Users need to own self.")
    personal_group = luser.home_group
    assert_equal(personal_group.name, luser.name)

    # Should always get original version of the LedgerUser record from a User.
    user.name = "Another Name Here"
    user.save!
    user.update_ledger_user_email_name
    user.reload
    luser.reload
    luser2 = user.ledger_user # Direct from rails lookup in the User record.
    assert_equal(luser.id, luser2.id)
    assert_equal(luser.id, user.create_or_get_ledger_user.id)
    luser3 = luser.latest_version
    assert_equal(luser.id, luser3.original_version_id)
    assert_not_equal(luser.name, user.name)
    assert_equal(luser3.name, user.name)
  end

  test "Weekly bonus points should accumulate with fading" do
    user = User.create!(
      name: "Bonus User",
      email: "SomeEMail@SomeDomain.com",
      password: "SomePassword",
      password_confirmation: "SomePassword",
      activated: true,
      activated_at: Time.zone.now,
    )
    luser = user.create_or_get_ledger_user
    luser.request_full_point_recalculation.update_current_points
    regular_points = luser.current_meh_points
    LedgerAwardCeremony.start_ceremony

    # Set up a weekly bonus.  Shouldn't get it until the following
    # ceremony happens.
    lbonus_explanation = LedgerPost.create!(creator_id: 0,
      subject: "Weekly eMail Bonus",
      content:
        "You get **10 Up** points each week for having a validated " \
        "e-mail address!")
    lbonus_link = LinkBonus.create!(creator_id: 0,
      bonus_explanation: lbonus_explanation, bonus_user: luser,
      bonus_points: 10, expiry_ceremony: 8,
      approved_parent: true, approved_child: true,
      rating_points_spent: 2.0,
      rating_points_boost_parent: 1.0,
      rating_points_boost_child: 1.0)
    assert(lbonus_link.approved_parent && lbonus_link.approved_child &&
      !lbonus_link.deleted, "Bonus link should be fully approved.")
    luser.update_current_points
    assert_in_delta(regular_points * 0.97 + 1.0,
      luser.current_meh_points, 0.0000001)

    # Check that the weekly bonus appears in the next ceremony and both
    # accumulates and fades in the ones after that.
    LedgerAwardCeremony.start_ceremony
    luser.update_current_points
    assert_in_delta((regular_points * 0.97 + 1.0) * 0.97 + 10.0,
      luser.current_meh_points, 0.0000001)
    LedgerAwardCeremony.start_ceremony
    luser.update_current_points
    assert_in_delta(10.0 * 0.97 + 10.0 +
      (regular_points * 0.97 + 1.0) * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001)
    # See if a full recalculation gives the same number.
    luser.current_meh_points = -2
    luser.current_ceremony = -1
    luser.save!
    luser.update_current_points
    assert_in_delta(10.0 * 0.97 + 10.0 +
      (regular_points * 0.97 + 1.0) * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001)
  end

  test "Shouldn't be able to add a second unique bonus" do
    luser = LedgerUser.create!(name: "Bonus User",
      email: "SomeEMail@SomeDomain.com", creator_id: 0,
      rating_points_spent_creating: 0.0, rating_points_boost_self: 0.0)
    luser.create_user # Create user, so we can see allowance and spending.
    lpost = ledger_posts(:lpost_one)
    # A couple of extra ceremonies, so we can test that relative ceremony
    # numbers are being used.
    LedgerAwardCeremony.start_ceremony("First ceremony, for testing...")
    LedgerUser.find(0).request_full_point_recalculation
    LedgerUser.find(0).create_user # Create User for the root, to see allowance.
    LedgerAwardCeremony.start_ceremony("Second ceremony, relative numbers.")

    lbonus_link = LinkBonusUnique.create!(creator_id: 0,
      bonus_explanation: lpost, bonus_user: luser, bonus_points: 1,
      expiry_ceremony: 8, approved_parent: true, approved_child: true,
      rating_points_spent: 1.0,
      rating_points_boost_parent: 0.5,
      rating_points_boost_child: 0.5)
    assert(lbonus_link.approved_parent && lbonus_link.approved_child &&
      !lbonus_link.deleted, "Unique Bonus link should be fully approved.")
    luser.update_current_points
    assert_in_delta(0.5, luser.current_meh_points, 0.0000001)
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(0.5, luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.user.weeks_allowance, 0.0000001)
    LedgerAwardCeremony.start_ceremony("Ceremony after bonus created, #3.")
    luser.update_current_points
    assert_in_delta(0.5 * 0.97 + 1.0, luser.current_meh_points, 0.0000001)
    assert_in_delta(1.0, luser.user.weeks_allowance, 0.0000001)

    # Make the second link, should fail.
    lbonus_second_link = LinkBonusUnique.create(creator_id: 0,
      bonus_explanation: lpost, bonus_user: luser, bonus_points: 2,
      approved_parent: true, approved_child: true)
    assert_equal(1, lbonus_second_link.errors.size,
      "Should fail to save a second unique bonus.")
    assert_equal("Creating a LinkBonusUnique which isn't unique - " \
      "there are other LinkBonus records with the same parent of " \
      "#{lpost} and child #{luser}.",
      lbonus_second_link.errors[:validate_uniqueness].first)
    LedgerAwardCeremony.start_ceremony("Ceremony #4, two since first bonus created.")
    luser.update_current_points
    assert_in_delta(0.5 * 0.97 * 0.97 + 1.0 * 0.97 + 1.0,
      luser.current_meh_points, 0.0000001)
    assert_in_delta(1.0, luser.user.weeks_allowance, 0.0000001)

    # Does full recalculation match incremental?
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(0.5 * 0.97 * 0.97 + 1.0 * 0.97 + 1.0,
      luser.current_meh_points, 0.0000001)

    # Try deleting the old bonus link.
    LedgerDelete.mark_records([lbonus_link], true,
      LedgerUser.find(0), "Should work.", "Testing deletion of First Bonus.")
    luser.reload
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)
    luser.update_current_points
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)

    # Make a new bonus link.
    lbonus_second_link = LinkBonusUnique.create!(creator_id: 0,
      bonus_explanation: lpost, bonus_user: luser, bonus_points: 3,
      expiry_ceremony: 8,
      approved_parent: true, approved_child: true,
      rating_points_spent: 1.0,
      rating_points_boost_parent: 0.0,
      rating_points_boost_child: 0.0)
    LedgerAwardCeremony.start_ceremony
    luser.update_current_points
    assert_in_delta(3.0,
      luser.current_meh_points, 0.0000001)
    LedgerAwardCeremony.start_ceremony # Ceremony #6.
    luser.update_current_points
    assert_in_delta(3.0 * 0.97 + 3.0,
      luser.current_meh_points, 0.0000001)
    assert_in_delta(3.0, luser.user.weeks_allowance, 0.0000001)

    # Try undeleting the original bonus link.  Should fail.
    assert_raise(RatingStoneErrors, "Undelete unique bonus") do
      LedgerDelete.mark_records([lbonus_link], false,
        LedgerUser.find(0), "Should fail", "Testing undeletion of First Bonus.")
    end
    luser.update_current_points
    assert_in_delta(3.0 * 0.97 + 3.0,
      luser.current_meh_points, 0.0000001)

    # Delete the second bonus, should have no bonus being applied.
    assert_equal(LedgerDelete,
      LedgerDelete.mark_records([lbonus_second_link], true,
        LedgerUser.find(0), "Should work.",
        "Deleting the second unique bonus.").class,
      "Delete didn't work?")
    luser.reload # No recalc, was database updated correctly?
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)
    luser.update_current_points
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(0.0,
      luser.current_meh_points, 0.0000001)

    # Now undelete the first bonus.  Should work this time.
    assert_equal(LedgerDelete,
      LedgerDelete.mark_records([lbonus_link], false,
        LedgerUser.find(0), "Should work.", "Undeleting the first bonus.")
        .class,
      "Undelete didn't work?")
    # Bonus created after ceremony 2, 0.5 direct boost, weekly bonus of
    # 1 point starting at ceremony #3.
    expected_points = 0.5 * 0.97 * 0.97 * 0.97 * 0.97 +
      1.0 +
      1.0 * 0.97 +
      1.0 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97
    luser.reload
    assert_in_delta(expected_points, luser.current_meh_points, 0.0000001)
    luser.update_current_points
    assert_in_delta(expected_points, luser.current_meh_points, 0.0000001)
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(expected_points, luser.current_meh_points, 0.0000001)

    LedgerAwardCeremony.start_ceremony("Ceremony 5 since first bonus created.")
    luser.update_current_points
    assert_in_delta(
      0.5 * 0.97 * 0.97 * 0.97 * 0.97 * 0.97 +
      1.0 +
      1.0 * 0.97 +
      1.0 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001
    )
  end

  test "See if bonus points get received and recalculated properly" do
    luser = ledger_users(:reader_user)
    user = luser.create_user # Create User, with weeks_allowance field.
    luser.update_current_points
    assert_in_delta(10.0, luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.current_up_points, 0.0000001)
    assert_in_delta(0.0, luser.current_down_points, 0.0000001)
    user.reload
    assert_in_delta(0.0, user.weeks_allowance, 0.0000001)
    assert_in_delta(0.0, user.weeks_spending, 0.0000001)
    LedgerAwardCeremony.start_ceremony # Ceremony #1 starts.
    luser.update_current_points
    assert_in_delta(10 * 0.97, luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.current_up_points, 0.0000001)
    assert_in_delta(0.0, luser.current_down_points, 0.0000001)
    user.reload
    assert_in_delta(0.0, user.weeks_allowance, 0.0000001)
    assert_in_delta(0.0, user.weeks_spending, 0.0000001)
    LedgerAwardCeremony.start_ceremony # 2 starts, fixture LinkBonus active now.
    luser.update_current_points
    assert_in_delta(10 * 0.97 * 0.97 + 10.0, luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.current_up_points, 0.0000001)
    assert_in_delta(0.0, luser.current_down_points, 0.0000001)
    user.reload
    assert_in_delta(10.0, user.weeks_allowance, 0.0000001)
    assert_in_delta(0.0, user.weeks_spending, 0.0000001)
    LedgerAwardCeremony.start_ceremony # 3, another week of existing bonus.
    luser.update_current_points
    assert_in_delta(10.0 * 0.97 * 0.97 * 0.97 + 10.0 * 0.97 + 10.0,
      luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.current_up_points, 0.0000001)
    assert_in_delta(0.0, luser.current_down_points, 0.0000001)
    user.reload
    assert_in_delta(10.0, user.weeks_allowance, 0.0000001)
    assert_in_delta(0.0, user.weeks_spending, 0.0000001)

    # Verify full recalculation the same as incremental, minus transient
    # initial 10 points from the fixture record creation.
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(10.0 * 0.97 + 10.0, luser.current_meh_points, 0.0000001)
    assert_in_delta(0.0, luser.current_up_points, 0.0000001)
    assert_in_delta(0.0, luser.current_down_points, 0.0000001)
    user.reload
    assert_in_delta(10.0, user.weeks_allowance, 0.0000001)
    assert_in_delta(0.0, user.weeks_spending, 0.0000001)
  end
end
