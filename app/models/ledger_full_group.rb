# frozen_string_literal: true

require_relative "ledger_subgroup.rb"

class LedgerFullGroup < LedgerSubgroup
  # Extra group properties too big to fit here are in a GroupSetting record.
  has_one :group_setting, dependent: :destroy, autosave: true

  after_create :group_after_create

  ##
  # Besides making a new ledger record when making a new version, copy the
  # group settings record too, into a new one.
  def append_version
    new_entry = super
    new_entry.group_setting = group_setting.dup
    new_entry
  end

  ##
  # Return true if the user can add posts to this group.  They may need to
  # spend some rating points on the group end of the link too.  Though note
  # that if the user is adding to a subgroup, this full group won't get the
  # points (creator/owner of the subgroup can manually transfer them later).
  # ErrorMessages is an optional array which will have an error message
  # appended if false is returned.  Of course, false just means a moderator
  # will need to approve the post.  luser can be any version of the user.
  def can_post?(luser, points_spent, error_messages = nil)
    # Creator of group can always do anything.
    return true if current_creator_id == luser.original_version_id

    # Test the various roles, starting with higher priority ones first, so
    # moderators can always approve a post even though they're also members.
    role = get_role(luser)

    # Message moderators can always post/approve a message.
    return true if role >= LinkRole::MESSAGE_MODERATOR

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

    # Non-member readers are sometimes allowed to write posts.
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
      "You (#{luser.latest_version}) are not allowed to even read the " \
        "\"#{name}\" group, let alone post.")
    false
  end

  ##
  # Returns the role the given user has in this group.  luser can be any
  # version of the user.
  def get_role(luser)
    # Creator is always valid; can't ban the creator.
    luser_original_id = luser.original_version_id
    return LinkRole::CREATOR if current_creator_id == luser_original_id

    # See which roles the user has been assigned, lowest priority one first.
    roles = LinkRole.where(
      parent_id: original_version_id,
      child_id: luser_original_id,
      deleted: false,
      approved_parent: true,
      approved_child: true,
    ).order(priority: :asc)

    # Banned takes precedence, even if other roles were assigned.
    low_role = roles.first
    return low_role.priority if
      low_role && low_role.priority <= LinkRole::BANNED

    # Now safe to check for owner, after banned, so we can ban an owner.
    return LinkRole::OWNER if creator_owner?(luser)

    # Look up the highest normal role assigned to the user.
    high_role = roles.last
    if high_role
      priority = high_role.priority
      # Don't allow silly levels of priority.  Only true owner or creator OK.
      priority = LinkRole::OWNER - 1 if priority >= LinkRole::OWNER
      return priority
    end

    # A default until we get wildcards and group settings working (insert that
    # code here), in which case the default becomes banned.
    LinkRole::READER
  end

  ##
  # Return true if the user has permission to do the things implied by the role.
  def role_test?(luser, test_role)
    # Creator has all permissions, even ones beyond LinkRole::CREATOR.
    return true if current_creator_id == luser.original_version_id

    test_role <= get_role(luser)
  end

  private

  ##
  # Creates the default settings record, if there isn't one.  And then sets
  # the back-ID field of that group settings record if it is incorrect.
  def group_after_create
    if group_setting.nil?
      self.group_setting = GroupSetting.create!(ledger_full_group_id: id)
    elsif group_setting.ledger_full_group_id != id
      group_setting.ledger_full_group_id = id
      group_setting.save!
    end
  end
end
