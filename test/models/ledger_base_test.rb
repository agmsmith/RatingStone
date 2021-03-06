# frozen_string_literal: true

require "test_helper"

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
      lbase.save!
    end
    assert_raise(ActiveRecord::InvalidForeignKey, "Creator must exist") do
      lbase = LedgerBase.new(creator_id: 123456, string1: "String Three")
      lbase.save!
    end
  end

  test "creator must be original version" do
    later_creator = ledger_users(:outsider_user).append_version
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
    original_lbase.save!
    assert_equal(original_lbase.latest_version.id, original_lbase.id)
    amended_lbase = original_lbase.append_version
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
    original_lbase.save!
    another_amend_lbase = original_lbase.append_version
    assert_equal(another_amend_lbase.string1, "An Amended string.")
    another_amend_lbase.string1 = "Amended a second time."
    another_amend_lbase.save!
    original_lbase.reload
    assert_equal(original_lbase.id, another_amend_lbase.original_id)
    assert_equal(original_lbase.amended_id, another_amend_lbase.id)
    assert_equal(amended_lbase.id, another_amend_lbase.amended_id)
    assert_not(another_amend_lbase.deleted)
    assert_equal(original_lbase.latest_version.id, another_amend_lbase.id)
    assert_equal(original_lbase.id, another_amend_lbase.original_version.id)
  end

  test "amended record race detection" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "It's a Race")
    original_lbase.save!
    amended_lbase1 = original_lbase.append_version
    amended_lbase1.string1 = "First One"
    amended_lbase2 = original_lbase.append_version
    amended_lbase2.string1 = "Second One"
    amended_lbase2.save!
    assert_raise(RatingStoneErrors, "Out of order appending versions") do
      amended_lbase1.save!
    end
    original_lbase.reload
    assert_equal("Second One", original_lbase.latest_version.string1)
    # Do it again, so the previous version isn't the original.
    amended_lbase1 = original_lbase.append_version
    amended_lbase1.string1 = "First One Again"
    amended_lbase2 = original_lbase.append_version
    amended_lbase2.string1 = "Second One Again"
    amended_lbase2.save!
    assert_raise(RatingStoneErrors, "Out of order appending versions again") do
      amended_lbase1.save!
    end
    original_lbase.reload
    assert_equal("Second One Again", original_lbase.latest_version.string1)
  end

  test "latest version flag" do
    original_lbase = LedgerBase.new(creator_id: 0, string1: "The original.")
    original_lbase.save!
    assert(original_lbase.latest_version?)
    amended_lbase = original_lbase.append_version
    amended_lbase.string1 = "The first amendment."
    assert(original_lbase.latest_version?)
    amended_lbase.save!
    assert(amended_lbase.latest_version?)
    assert(original_lbase.latest_version?)
    original_lbase.reload
    assert_not(original_lbase.latest_version?)
    assert(amended_lbase.latest_version?)

    reamended_lbase = amended_lbase.append_version
    reamended_lbase.string1 = "The second amendment."
    assert_not(original_lbase.latest_version?)
    assert(amended_lbase.latest_version?)
    reamended_lbase.save!
    amended_lbase.reload
    original_lbase.reload
    assert_not(original_lbase.latest_version?)
    assert_not(amended_lbase.latest_version?)
    assert(reamended_lbase.latest_version?)
    lastamended_lbase = original_lbase.append_version
    lastamended_lbase.string1 = "The third amendment."
    lastamended_lbase.is_latest_version = false
    lastamended_lbase.save!
    original_lbase.reload
    amended_lbase.reload
    reamended_lbase.reload
    assert_not(original_lbase.latest_version?)
    assert_not(amended_lbase.latest_version?)
    assert_not(reamended_lbase.latest_version?)
    assert(lastamended_lbase.latest_version?)
  end

  test "creator_owner? function" do
    lgroup = ledger_full_groups(:group_all)
    assert lgroup.creator_owner?(ledger_users(:group_creator_user))
    assert lgroup.creator_owner?(ledger_users(:group_owner_user))
    assert_not lgroup.creator_owner?(ledger_users(:message_moderator_user))
    assert_not lgroup.creator_owner?(ledger_users(:member_moderator_user))
    assert_not lgroup.creator_owner?(ledger_users(:member_user))
    assert_not lgroup.creator_owner?(ledger_users(:outsider_user))
    assert_not lgroup.creator_owner?(ledger_users(:root_ledger_user_fixture))
    assert_raise(RatingStoneErrors, "Passing in a Post, not LedgerUser") do
      lgroup.creator_owner?(ledger_posts(:lpost_one))
    end
    assert_raise(RatingStoneErrors, "Passing in nil instead of LedgerUser") do
      lgroup.creator_owner?(nil)
    end

    # Avoiding fixtures, make our own owner record so post-create callback gets
    # run, test has_owners field, also test with a versioned user and post.
    lpost = ledger_posts(:lpost_one).append_version
    lpost.content = "Some edited content here, new version."
    lpost.creator = ledger_users(:reader_user) # Change creator.
    lpost.save!
    lpost.reload
    assert_equal(ledger_users(:reader_user).id, lpost.current_creator_id)
    assert_equal(0, lpost.original_version.creator_id)
    luser = ledger_users(:outsider_user).append_version
    luser.email = "NewVersionOfUser@example.com"
    luser.save!
    luser.reload
    assert_not(lpost.original_version.has_owners)
    assert_not(lpost.creator_owner?(luser))
    lowner = LinkOwner.create!(parent: luser.original_version,
      child: lpost.original_version, creator: luser.original_version)
    assert(lpost.original_version.has_owners)
    assert_not(lpost.creator_owner?(luser),
      "Permission not approved yet in #{lowner}.")
    LedgerApprove.approve_records([lowner],
      ledger_users(:reader_user), "Testing creator_owner?",
      "Creator of post approving ownership change.")
    assert(lpost.creator_owner?(luser),
      "Should now have permission in #{lowner.reload}.")
  end

  test "allowed_to_view? function" do
    # Creator, owner should be allowed to view, nobody else for a stand-alone
    # object.  Then see if you have access to a group if you are a member.
    # Then see if you can access a content object (a post) if you are a member
    # of the group it is in.
    luser = ledger_users(:outsider_user)
    lpost = LedgerPost.create!(creator: luser, subject: "Some Subject",
      content: "This is a test post to see if people can view it.")
    assert(lpost.allowed_to_view?(luser))
    user_ins = [
      ledger_users(:group_creator_user),
      ledger_users(:group_owner_user),
      ledger_users(:message_moderator_user),
      ledger_users(:member_moderator_user),
      ledger_users(:member_user),
      ledger_users(:reader_user),
      ledger_users(:root_ledger_user_fixture),
      users(:malory).ledger_user,
    ]
    user_outs = [ledger_users(:message_moderator2_user),
                 ledger_users(:undesirable_user)]
    (user_ins + user_outs).each do |x|
      assert_not(lpost.allowed_to_view?(x), "#{x} should not be able to view.")
    end

    # See who can view the group description.  Currently default role is Reader
    # until we get wildcards working, so everbody can see it.
    lgroup = ledger_subgroups(:group_dogs)
    user_ins.each do |x|
      assert(lgroup.allowed_to_view?(x), "#{x} should be able to view.")
    end
    user_outs.each do |x|
      assert_not(lgroup.allowed_to_view?(x), "#{x} should not be able to view.")
    end

    # Add the post to a subgroup.  First with a partially unapproved group link.
    group_content = LinkGroupContent.create!(parent: lgroup, child: lpost,
      creator: luser)
    (user_ins + user_outs).each do |x|
      assert_not(lpost.allowed_to_view?(x), "#{x} should not be able to view.")
    end

    # Now approve the group end of the link between post and group.
    assert_equal("LedgerApprove", LedgerApprove.approve_records([group_content],
      ledger_users(:message_moderator_user), "Inside a test.",
      "Because we want to see who can view an approved post.").class.name)
    user_ins.each do |x|
      assert(lpost.allowed_to_view?(x), "#{x} should be able to view.")
    end
    user_outs.each do |x|
      assert_not(lpost.allowed_to_view?(x), "#{x} should not be able to view.")
    end

    # Now delete the approval.
    assert_equal("LedgerDelete", LedgerDelete.delete_records([group_content],
      ledger_users(:message_moderator_user), "Inside a test again.",
      "Want to see if deleting a group content link works.").class.name)
    (user_ins + user_outs).each do |x|
      assert_not(lpost.allowed_to_view?(x), "#{x} should not be able to view.")
    end
  end
end
