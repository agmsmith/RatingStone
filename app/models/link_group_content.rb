# frozen_string_literal: true

class LinkGroupContent < LinkBase
  alias_attribute :disapproval_messages, :string1

  validate :validate_parent_is_group

  ##
  # Besides the creator of the link, the message moderator in the linked to
  # group can also delete this link (rather than having it hang around as
  # a post waiting for moderation).
  def creator_owner?(luser)
    return true if super
    parent.permission?(luser, LinkRole::MESSAGE_MODERATOR)
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end (a group) of this link to a post or other content.
  def permission_to_change_parent_approval(luser)
    parent.permission?(luser, LinkRole::MESSAGE_MODERATOR)
  end

  private

  ##
  # Automatically approve the end of the link when the creator is a member of
  # the parent group in a role with high enough priviledge to approve.
  def do_automatic_approvals
    super # Do the usual owner and creator approvals.

    # Check if the creator is a member of the parent group with enough
    # priviledge to add posts to the group.
    errors = []
    if parent.can_post?(creator, rating_points_boost_parent, errors)
      self.approved_parent = true
    else
      self.disapproval_messages = errors.join("  ").truncate(255)
    end
  end

  def validate_parent_is_group
    parent.is_a?(LedgerSubgroup)
  end
end
