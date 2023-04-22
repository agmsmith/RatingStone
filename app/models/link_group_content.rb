# frozen_string_literal: true

class LinkGroupContent < LinkBase
  alias_attribute :group, :parent
  alias_attribute :group_id, :parent_id
  alias_attribute :content, :child
  alias_attribute :content_id, :child_id
  alias_attribute :disapproval_messages, :string1

  validate :validate_parent_and_child_types

  before_create :set_default_description

  ##
  # Besides the creator of the link, the creator of the content, and the
  # message moderator role in the linked to group can also delete this link
  # (rather than having it hang around as a post waiting for moderation).
  def creator_owner?(luser)
    return true if super

    return true if permission_to_change_child_approval(luser)

    permission_to_change_parent_approval(luser) # More expensive method last.
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end (a group) of this link to a post or other content.  Note that
  # role_test includes creator_owner functionality so we skip that test.
  def permission_to_change_parent_approval(luser)
    parent.role_test?(luser, LinkRole::MESSAGE_MODERATOR)
  end

  def initial_approval_state
    approvals = super # Do the usual owner and creator approvals.
    # If the parent is already approved, skip the role test.
    return approvals if approvals[APPROVE_PARENT]

    # Check if the creator is a member of the parent group with enough
    # privilege and points spent to add posts to the group.
    errors = []
    if parent.can_post?(creator, rating_points_boost_parent, errors)
      approvals[APPROVE_PARENT] = true
    else
      self.disapproval_messages = errors.join("  ").truncate(255)
    end
    approvals
  end

  private

  def set_default_description
    return unless string1.empty?

    self.string1 = "#{child.to_s.truncate(80)} is content in group " \
      "#{parent.to_s.truncate(80)}."
  end

  def validate_parent_and_child_types
    errors.add(:nongroup, "Parent isn't a group for #{self}") \
      unless parent.is_a?(LedgerSubgroup)
    errors.add(:noncontent, "Child isn't a post for #{self}") \
      unless child.is_a?(LedgerPost)
  end
end
