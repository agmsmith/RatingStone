# frozen_string_literal: true

require 'test_helper'

class LedgerUserTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_seed
  end

  test "Root user zero should exist" do
    lu_root = LedgerUser.find_by(id: 0) # Not find() so nil result allowed.
    assert_not_nil(lu_root, "Root ledger user should exist at id #0")
    assert_match(/root/i, lu_root.string1,
      "Root user should have Root in their name")
    assert_equal(lu_root.creator_id, 0,
      "Root user should be created by id #0 (itself)")
  end

# bleeble
#See if ledger user gets created for a regular user.
#See if changing a regular user changes ledger name and email.

end
