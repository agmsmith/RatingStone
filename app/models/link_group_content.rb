# frozen_string_literal: true

class LinkGroupContent < LinkBase
  alias_attribute :disapproval_messages, :string1

  validate :validate_parent_and_child_types

  ##
  # Besides the creator of the link, the message moderator in the linked to
  # group can also delete this link (rather than having it hang around as
  # a post waiting for moderation).
  def creator_owner?(luser)
    return true if super
puts "TestIt #{self} starting special creator_owner test for #{luser}."
result =    parent.role_test?(luser, LinkRole::MESSAGE_MODERATOR)
puts "TestIt #{self} result of special creator_owner test for #{luser} is #{result}."
result
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end (a group) of this link to a post or other content.
  def permission_to_change_parent_approval(luser)
puts "TestIt Special LinkGroupContent case starting #{self} permission_to_change_parent_approval for #{luser}."
result =    parent.role_test?(luser, LinkRole::MESSAGE_MODERATOR)
puts "TestIt Special LinkGroupContent case finishing #{self} permission_to_change_parent_approval for #{luser} result #{result}."
result
  end

  private

  ##
  # Automatically approve the group end of the link when the creator is a
  # member of the group in a role with high enough priviledge to approve.
  def do_automatic_approvals
    super # Do the usual owner and creator approvals.
    return if approved_parent # Already approved, skip group role test.

puts "TestIt #{self} do_automatic_approvals extra test for #{creator}."
    # Check if the creator is a member of the parent group with enough
    # priviledge and points spent to add posts to the group.
    errors = []
    if parent.can_post?(creator, rating_points_boost_parent, errors)
      self.approved_parent = true
    else
      self.disapproval_messages = errors.join("  ").truncate(255)
    end
puts "TestIt #{self} do_automatic_approval extra test for #{creator} result is #{approved_parent}."
  end

  def validate_parent_and_child_types
    errors.add(:nongroup, "Parent isn't a group for #{self}") \
      unless parent.is_a?(LedgerSubgroup)
    errors.add(:noncontent, "Child isn't a content object for #{self}") \
      unless child.is_a?(LedgerContent)
  end
end
