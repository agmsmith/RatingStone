# frozen_string_literal: true

class LinkRole < LinkBase
  alias_attribute :priority, :number1
  alias_attribute :description, :string1
  alias_attribute :group, :parent
  alias_attribute :group_id, :parent_id
  alias_attribute :user, :child
  alias_attribute :user_id, :child_id

  validate :validate_parent_and_child_types

  before_create :set_default_role_description

  # The various different role priority numbers.  Separated by 10s so we have
  # space to insert future roles.  Each role usually includes functionality of
  # the lower ones (see database design document for exceptions).
  BANNED = 10
  READER = 20
  MEMBER = 30
  OPINIONATOR = 40
  META_OPINIONATOR = 50
  MESSAGE_MODERATOR = 60
  MEMBER_MODERATOR = 70
  OWNER = 80
  CREATOR = 90

  # Designed so you can say "Person X is a ___ in group Y".
  ROLE_NAMES = {
    BANNED => "banned user",
    READER => "reader",
    MEMBER => "member",
    OPINIONATOR => "opinion maker",
    META_OPINIONATOR => "maker of opinions about opinions",
    MESSAGE_MODERATOR => "message moderator",
    MEMBER_MODERATOR => "member moderator",
    OWNER => "owner",
    CREATOR => "creator",
  }

  ##
  # Besides the creator of the link, the user being given a role, and the
  # message moderator role in the linked to group can also delete this link
  # (rather than having it hang around waiting for moderation).
  def creator_owner?(luser)
    return true if super

    return true if permission_to_change_child_approval(luser)

    permission_to_change_parent_approval(luser) # More expensive method last.
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end (a group) of this link about assigning a role.  Note that
  # role_test includes creator_owner functionality so we skip that test.
  def permission_to_change_parent_approval(luser)
    parent.role_test?(luser, LinkRole::MEMBER_MODERATOR)
  end

  private

  ##
  # Convert the numerical priority into words if no description yet.
  def set_default_role_description
    return unless description.empty?

    index = priority.to_i / 10 * 10
    index = BANNED if index < BANNED
    index = CREATOR if index > CREATOR
    desc = ROLE_NAMES[index]
    desc += " (a nonstandard #{priority})" if index != priority
    self.description = "#{child} is a #{desc} in group #{parent}.".truncate(255)
  end

  def validate_parent_and_child_types
    errors.add(:nongroup, "Parent object needs to be a LedgerFullGroup " \
      "for #{self}") unless group.is_a?(LedgerFullGroup)
    errors.add(:nonuser, "Child object needs to be a LedgerUser for #{self}") \
      unless user.is_a?(LedgerUser)
  end
end
