# frozen_string_literal: true

class LinkRole < LinkBase
  alias_attribute :role_priority, :number1
  alias_attribute :role_description, :string1

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

  ROLE_NAMES = {
    BANNED => 'banned',
    READER => 'reader',
    MEMBER => 'member',
    MESSAGE_MODERATOR => 'message moderator',
    META_MODERATOR => 'meta moderator',
    MEMBER_MODERATOR => 'member moderator',
    OWNER => 'owner',
    CREATOR => 'creator',
  }
end
