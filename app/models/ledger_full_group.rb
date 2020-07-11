# frozen_string_literal: true

class LedgerFullGroup < LedgerSubgroup
  # Extra group properties too big to fit here are in a GroupSetting record.
  has_one :group_setting, dependent: :destroy, autosave: true

  ##
  # Return true if the user has permission to do the things implied by the role.
  def permission?(luser, test_role)
    # Creator has all permissions.
    return true if creator_id == luser.original_version_id

    # See which roles the user has been assigned, lowest priority one first.
    roles = LinkRole.where(parent_id: original_version_id,
      child_id: luser.original_version_id, deleted: false,
      approved_parent: true, approved_child: true).order(role_priority: :asc)

    # Banned has no permissions, even if other roles were assigned.
    low_role = roles.first
    return false if low_role && low_role.role_priority <= LinkRole::BANNED

    # The normal permissions level test.
    high_role = roles.last
    return true if high_role && high_role.role_priority >= test_role

    # If looking for the owner.
    if creator_owner?(luser)
      return true if test_role <= LinkRole::OWNER
    end

    # Later on do wildcard searches here.
    false
  end
end
