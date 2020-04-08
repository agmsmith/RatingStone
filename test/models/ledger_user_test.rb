# frozen_string_literal: true

require 'test_helper'

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
      password_confirmation: "SomePassword",
      activated: true,
      activated_at: Time.zone.now
    )
    luser = user.ledger_user
    luser.birthday = Time.new(2020, 2, 20, 20, 20, 20) # Palindromic date.
    luser.save
    assert_equal(user.id, luser.user_id, "User id should be in LedgerUser")
    assert_equal(luser.id, user.ledger_user_id, "LedgerUser should be in User")
  end

  test "Changes in name and e-mail in a User should show up in LedgerUser" do
    user = User.create!(
      name:  "Test Regular User",
      email: "SomeEMail@SomeDomain.com",
      password: "SomePassword",
      password_confirmation: "SomePassword",
      activated: true,
      activated_at: Time.zone.now
    )
    luser = user.ledger_user
    assert_equal(luser.name, user.name)
    assert_equal(luser.email, user.email)

    new_name = "A New Name"
    user.name = new_name
    user.save
    assert_equal(new_name, luser.name)

    new_email = "A New E-Mail"
    user.email = new_email
    user.save
    assert_equal(new_email, luser.email)
  end
end
