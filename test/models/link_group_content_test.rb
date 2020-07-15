# frozen_string_literal: true

require 'test_helper'

class LinkGroupContentTest < ActiveSupport::TestCase
  test "Parent should be a Group" do
    lsubgroup = ledger_subgroups(:group_dogs)
    lpost = ledger_posts(:lpost_two)
    luser_post_creator = lpost.creator

    # Normal situation should be valid.
    link_group = LinkGroupContent.new(parent: lsubgroup, child: lpost,
      creator: luser_post_creator)
    assert(link_group.valid?)

    # Child and parent reversed.  Type problem should be detected.
    link_group = LinkGroupContent.new(parent: lpost, child: lsubgroup,
      creator: luser_post_creator)
    assert_not(link_group.valid?)
puts "TestIt Errors are #{link_group.errors}."
    assert_equal(link_group.errors.count, 2)
  end
end
