# frozen_string_literal: true

class LinkRole < LinkBase
  alias_attribute :role_priority, :number1
  alias_attribute :role_description, :string1

  before_create :set_default_role_description

  # The various different role priority numbers.  Separated by 10s so we have
  # space to insert future roles.  Each role usually includes functionality of
  # the lower ones (see database design document for exceptions).
  BANNED = 10
  READER = 20
  MEMBER = 30
  MESSAGE_MODERATOR = 40
  META_MODERATOR = 50
  MEMBER_MODERATOR = 60
  OWNER = 70
  CREATOR = 80

  # Designed so you can say "Person X is a ___ in group Y".
  ROLE_NAMES = {
    BANNED => 'banned user',
    READER => 'reader',
    MEMBER => 'member',
    MESSAGE_MODERATOR => 'message moderator',
    META_MODERATOR => 'meta moderator',
    MEMBER_MODERATOR => 'member moderator',
    OWNER => 'owner',
    CREATOR => 'creator',
  }

  private

  ##
  # Convert the numerical role_priority into words if no description yet.
  def set_default_role_description
    return unless role_description.empty?
    index = role_priority.to_i / 10 * 10
    index = BANNED if index < BANNED
    index = CREATOR if index > CREATOR
    desc = ROLE_NAMES[index]
    desc += " (#{role_priority})" if index != role_priority
    self.role_description = "#{child.latest_version.name} is a #{desc} in " \
      "the #{parent.latest_version.name} group.".truncate(255)
  end
end
