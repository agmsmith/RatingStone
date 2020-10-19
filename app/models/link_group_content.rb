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
  # Besides the creator of the link, the message moderator in the linked to
  # group can also delete this link (rather than having it hang around as
  # a post waiting for moderation).  And the linked-to content owner can
  # also delete the link.
  def creator_owner?(luser)
    return true if super
    return true if parent.role_test?(luser, LinkRole::MESSAGE_MODERATOR)
    child.creator_owner?(luser)
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end (a group) of this link to a post or other content.  Note that
  # role_test includes creator_owner functionality so we skip that test.
  def permission_to_change_parent_approval(luser)
    parent.role_test?(luser, LinkRole::MESSAGE_MODERATOR)
  end

  private

  ##
  # Automatically approve the group end of the link when the creator is a
  # member of the group in a role with high enough priviledge to approve.
  def do_automatic_approvals
    super # Do the usual owner and creator approvals.
    return if approved_parent # Already approved, skip group role test.

    # Check if the creator is a member of the parent group with enough
    # priviledge and points spent to add posts to the group.
    errors = []
    if parent.can_post?(creator, rating_points_boost_parent, errors)
      self.approved_parent = true
    else
      self.disapproval_messages = errors.join("  ").truncate(255)
    end
  end

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child.to_s.truncate(80)} is content in group " \
      "#{parent.to_s.truncate(80)}."
  end

  def validate_parent_and_child_types
    errors.add(:nongroup, "Parent isn't a group for #{self}") \
      unless parent.is_a?(LedgerSubgroup)
    errors.add(:noncontent, "Child isn't a content object for #{self}") \
      unless child.is_a?(LedgerContent)
  end
end
