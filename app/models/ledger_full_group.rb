# frozen_string_literal: true

class LedgerFullGroup < LedgerSubgroup
  # Extra group properties too big to fit here are in a GroupSetting record.
  has_one :group_setting, dependent: :destroy, autosave: true

  ##
  # Return true if the user can add posts to this group.  They may need to
  # spend some rating points on the group end of the link too.  Though note
  # that if the user is adding to a subgroup, this full group won't get the
  # points (creator/owner of the subgroup can manually transfer them later).
  # ErrorMessages is an optional array which will have an error message
  # appended if false is returned.  Of course, false just means a moderator
  # will need to approve the post.
  def can_post?(luser, points_spent, error_messages = nil)
    # Creator of group can always post without moderation.  But not owners.
    return true if creator_id == luser.original_version_id

    role = get_role(luser)

    # Membership has priviledges.
    if role >= LinkRole::MEMBER
      unless group_setting.auto_approve_member_posts
        error_messages&.push(
          "Currently not doing automatic approval of member's posts in the " \
          "\"#{name}\" group.")
        return false
      end
      return true if points_spent >= group_setting.min_points_member_post &&
        points_spent <= group_setting.max_points_member_post
      error_messages&.push(
        "Need to spend between #{group_setting.min_points_member_post} and " \
        "#{group_setting.max_points_member_post} points on the " \
        "\"#{name}\" group in order to get your member message pre-approved.")
      return false
    end

    # Non-members are sometimes allowed to read posts.
    if role >= LinkRole::READER
      unless group_setting.auto_approve_non_member_posts
        error_messages&.push(
          "Currently not doing automatic approval of non-member's posts in " \
          "the \"#{name}\" group.")
        return false
      end
      return true if points_spent >=
        group_setting.min_points_non_member_post &&
        points_spent <= group_setting.max_points_non_member_post
      error_messages&.push(
        "Need to spend between #{group_setting.min_points_non_member_post} " \
        "and #{group_setting.max_points_non_member_post} points on the " \
        "\"#{name}\" group in order to get your non-member message " \
        "pre-approved.")
      return false
    end

    error_messages&.push(
      "You are not allowed to even read the \"#{name}\" group, let alone post.")
    false
  end

  ##
  # Returns the role the given user has in this group.
  def get_role(luser)
    return LinkRole::CREATOR if creator_id == luser.original_version_id

    # See which roles the user has been assigned, lowest priority one first.
    roles = LinkRole.where(parent_id: original_version_id,
      child_id: luser.original_version_id, deleted: false,
      approved_parent: true, approved_child: true).order(role_priority: :asc)

    # Banned takes precedence, even if other roles were assigned.
    low_role = roles.first
    return low_role.role_priority if
      low_role && low_role.role_priority <= LinkRole::BANNED

    # Now safe to check for owner, after banned, so we can ban an owner.
    return LinkRole::OWNER if creator_owner?(luser)

    # Look up the highest normal role assigned to the user.
    high_role = roles.last
    if high_role
      priority = high_role.role_priority
      # Don't allow silly levels of priority.
      priority = LinkRole::OWNER - 10 if priority >= LinkRole::OWNER
      return priority
    end

    # A default until we get wildcards working (insert that code here),
    # in which case the default becomes banned.
    LinkRole::READER
  end

  ##
  # Return true if the user has permission to do the things implied by the role.
  def permission?(luser, test_role)
    # Creator has all permissions.
    return true if creator_id == luser.original_version_id

    best_role = get_role(luser) # Easier debugging if we store it in a variable.
    test_role <= best_role
  end
end
