# frozen_string_literal: true

require "test_helper"

class LedgerUserTest < ActiveSupport::TestCase
  def setup
    # Create the root user/object and sysop user.
    Rails.application.load_seed
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
      password_confirmation: "SomePassword"
    )
    user.activate
    luser = user.ledger_user
    luser.save!
    assert_equal(luser.id, user.ledger_user_id, "LedgerUser should be in User")
    assert_equal(luser.id, luser.creator_id, "Users should be created by self")
    assert(luser.creator_owner?(luser), "Users need to own self.")
    personal_group = luser.home_group
    assert_equal(personal_group.name, luser.name)
  end

  test "Changes in name and e-mail in a User should show up in LedgerUser" do
    old_name = "Test Regular User"
    new_name = "A New Name"

    user = User.create!(
      name: old_name,
      email: "SomeEMail@SomeDomain.com",
      password: "SomePassword",
      password_confirmation: "SomePassword",
      activated: true,
      activated_at: Time.zone.now
    )
    luser = user.ledger_user
    saved_original_luser_id = luser.id
    assert_equal(luser.creator_id, saved_original_luser_id,
      "Should have self as creator for a LedgerUser")
    assert_equal(luser.name, user.name)
    assert_equal(luser.email, user.email) # Note email is by now downcased.

    user.name = new_name
    assert_nil(luser.amended_id, "Should not yet be an amended user")
    user.save!
    luser.reload # Old ledger version record here, should still have old name.
    assert_not_nil(luser.amended_id, "Should be an amended user after changes")
    assert_equal(luser.name, old_name)
    luser_modified = luser.latest_version
    assert_equal(luser_modified.name, new_name)
    assert_equal(luser_modified.id, user.ledger_user.id,
      "Should get latest LedgerUser record version when asking User for it")
    assert_equal(saved_original_luser_id, luser_modified.creator_id,
      "Creator should be original LedgerUser record in amended record")
    assert_not_equal(saved_original_luser_id, luser_modified.id)

    new_email = "newmail@somewhere.com"
    user.email = new_email
    user.save!
    luser = user.ledger_user
    assert_equal(new_email, luser.email)
  end

  test "Weekly bonus points should accumulate with fading" do
    LedgerAwardCeremony.clear_ceremony_cache # Avoid a test framework problem.
    user = User.create!(
      name: "Bonus User",
      email: "SomeEMail@SomeDomain.com",
      password: "SomePassword",
      password_confirmation: "SomePassword",
      activated: true,
      activated_at: Time.zone.now
    )
    luser = user.ledger_user
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
      bonus_points: 10, approved_parent: true, approved_child: true)
    assert(lbonus_link.approved_parent && lbonus_link.approved_child &&
      !lbonus_link.deleted, "Bonus link should be fully approved.")

    # Check that the weekly bonus appears in the next ceremony and both
    # accumulates and fades in the ones after that.
    luser.update_current_points
    assert_in_delta(0.0, luser.current_meh_points, 0.0000001)
    LedgerAwardCeremony.start_ceremony
    luser.update_current_points
    assert_in_delta(10.0, luser.current_meh_points, 0.0000001)
    LedgerAwardCeremony.start_ceremony
    luser.update_current_points
    assert_in_delta(10.0 + 10.0 * 0.97, luser.current_meh_points, 0.0000001)
    # See if a full recalculation gives the same number.
    luser.current_meh_points = -2
    luser.current_ceremony = -1
    luser.save!
    luser.update_current_points
    assert_in_delta(10.0 + 10.0 * 0.97, luser.current_meh_points, 0.0000001)
  end

  test "Shouldn't be able to add a second unique bonus" do
    luser = LedgerUser.create!(name: "Bonus User",
      email: "SomeEMail@SomeDomain.com", creator_id: 0)
    lpost = ledger_posts(:lpost_one)

    # A couple of extra ceremonies, so we can test that relative ceremony
    # numbers are being used.
    LedgerAwardCeremony.start_ceremony("First ceremony, for testing...")
    LedgerAwardCeremony.start_ceremony("Second ceremony, relative numbers.")

    lbonus_link = LinkBonusUnique.create!(creator_id: 0,
      bonus_explanation: lpost, bonus_user: luser, bonus_points: 1,
      approved_parent: true, approved_child: true)
    assert(lbonus_link.approved_parent && lbonus_link.approved_child &&
      !lbonus_link.deleted, "Unique Bonus link should be fully approved.")
    LedgerAwardCeremony.start_ceremony("Ceremony #1 since first bonus created.")
    luser.update_current_points
    assert_in_delta(1.0, luser.current_meh_points, 0.0000001)

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
    LedgerAwardCeremony.start_ceremony("Ceremony #2 since first bonus created.")
    luser.update_current_points
    assert_in_delta(1.0 + 1.0 * 0.97, luser.current_meh_points, 0.0000001)

    # Does full recalculation match incremental?
    luser.request_full_point_recalculation
    luser.update_current_points
    assert_in_delta(1.0 + 1.0 * 0.97, luser.current_meh_points, 0.0000001)

    # Try deleting the old bonus link and make a new one.
    LedgerDelete.mark_records([lbonus_link], true,
      LedgerUser.find(0), "Should work.", "Testing deletion of First Bonus.")
    lbonus_second_link = LinkBonusUnique.create!(creator_id: 0,
      bonus_explanation: lpost, bonus_user: luser, bonus_points: 3,
      approved_parent: true, approved_child: true)
    LedgerAwardCeremony.start_ceremony("Ceremony #3 since first bonus created.")
    luser.update_current_points
    assert_in_delta(3.0, luser.current_meh_points, 0.0000001)
    LedgerAwardCeremony.start_ceremony("Ceremony #4 since first bonus created.")
    luser.update_current_points
    assert_in_delta(3.0 + 3.0 * 0.97, luser.current_meh_points, 0.0000001)

    # Try undeleting the original bonus link.  Should fail.
    assert_raise(RatingStoneErrors, "Undelete unique bonus") do
      LedgerDelete.mark_records([lbonus_link], false,
        LedgerUser.find(0), "Should fail", "Testing undeletion of First Bonus.")
    end
    luser.reload
    luser.update_current_points
    assert_in_delta(3.0 + 3.0 * 0.97, luser.current_meh_points, 0.0000001)

    # Delete the second bonus, should have no bonus being applied.
    assert_equal(LedgerDelete,
      LedgerDelete.mark_records([lbonus_second_link], true,
        LedgerUser.find(0), "Should work.",
        "Deleting the second unique bonus.").class,
      "Delete didn't work?")
    luser.reload # Deletion of bonus side-effects the LedgerUser record.
    assert_in_delta(0.0, luser.current_meh_points, 0.0000001)
    luser.update_current_points
    assert_in_delta(0.0, luser.current_meh_points, 0.0000001)

    # Now undelete the first bonus.  Should work this time.
    assert_equal(LedgerDelete,
      LedgerDelete.mark_records([lbonus_link], false,
        LedgerUser.find(0), "Should work.", "Undeleting the first bonus.")
        .class,
      "Undelete didn't work?")
    luser.reload
    assert_in_delta(
      1.0 +
      1.0 * 0.97 +
      1.0 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001
    )
    luser.update_current_points
    assert_in_delta(
      1.0 +
      1.0 * 0.97 +
      1.0 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001
    )
    LedgerAwardCeremony.start_ceremony("Ceremony #5 since first bonus created.")
    luser.update_current_points
    assert_in_delta(
      1.0 +
      1.0 * 0.97 +
      1.0 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97 +
      1.0 * 0.97 * 0.97 * 0.97 * 0.97,
      luser.current_meh_points, 0.0000001
    )
    # TODO: Test approval changes too.  See if points get spent.  See if points get received.
  end
end
