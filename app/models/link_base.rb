# frozen_string_literal: true

class LinkBase < ApplicationRecord
  validate :validate_link_original_versions_referenced
  before_create :do_automatic_approvals

  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
  belongs_to :creator, class_name: :LedgerBase, optional: false

  has_many :aux_link_ups, class_name: :AuxLink, foreign_key: :child_id
  has_many :aux_link_ancestors, through: :aux_link_ups, source: :parent

  ##
  # Return a user readable description of the object.  Besides some unique
  # identification so we can find it in the database, have some readable
  # text so the user can guess which object it is (like the content of a post).
  # Usually used in error messages, which the user may see.  Max 255 characters.
  def to_s
    "#{base_s} (num1: #{number1}, " \
      "notes: #{string1.truncate(40)}, " \
      "parent #{approved_parent.to_s[0].upcase}: " \
      "#{parent.to_s.truncate(75)}, " \
      "child #{approved_child.to_s[0].upcase}: " \
      "#{child.to_s.truncate(75)})".truncate(255)
  end

  ##
  # Return a basic user readable identification of an object (ID and class).
  def base_s
    "##{id} #{self.class.name}"
  end

  ##
  # See if the given user is allowed to delete and otherwise modify this record.
  # Has to be the creator of the object.  You can't have owners of a link,
  # though owners do get involved for approvals of link ends, but that's a
  # separate concept.  Returns true if they have permission.  Subclasses may
  # override this to add more people.  The policy is that if someone needs to
  # approve a link, they should also be able to delete it.
  def creator_owner?(luser)
    raise RatingStoneErrors,
      "Need a LedgerUser, not a #{luser.class.name} " \
      "object to test against.  Self: #{self}, supposed user: #{luser}" \
      unless luser.is_a?(LedgerUser)
    creator_id == luser.original_version_id
  end

  # TODO: Implement points apply for links.
  def legitimate_child
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end of this link.  Subclasses (like links from groups to posts)
  # may override this.
  def permission_to_change_parent_approval(luser)
    parent.creator_owner?(luser)
  end

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the child end of this link.  Subclasses probably won't override this.
  def permission_to_change_child_approval(luser)
    child.creator_owner?(luser)
  end

  ##
  # Find out who approved me.  Returns a list of LedgerApprove
  # records, with the most recent first.  Works by searching
  # the AuxLink records for references to this particular record.
  def approved_by
    LedgerBase.joins(:aux_link_downs)
      .where({
        aux_links: { child_id: id },
        type: [:LedgerApprove],
      })
      .order(created_at: :desc)
  end

  ##
  # Find out who deleted me.  Returns a list of LedgerDelete records, with the
  # most recent first.  Works by searching the AuxLink records for references
  # to this particular record.
  def deleted_by
    LedgerBase.joins(:aux_link_downs)
      .where({
        aux_links: { child_id: id },
        type: [:LedgerDelete],
      })
      .order(created_at: :desc)
  end

  ##
  # Callback method that marks a LinkBase object as approved.  Hub record is
  # the LedgerApprove instance being processed.  Check for permissions and
  # raise an exception if the user isn't allowed to approve it.
  def mark_approved(hub)
    luser = hub.creator # Already original version.
    parent_change_permitted = permission_to_change_parent_approval(luser)
    child_change_permitted = permission_to_change_child_approval(luser)
    raise RatingStoneErrors, "#mark_approved: User #{luser.latest_version} " \
      "doesn't have permission to change any approvals in record #{self}." \
      unless parent_change_permitted || child_change_permitted

    self.approved_parent = hub.new_marking_state if parent_change_permitted
    self.approved_child = hub.new_marking_state if child_change_permitted
    save!
  end

  ##
  # Callback method that marks a LinkBase object as deleted.  Hub record is
  # the LedgerDelete instance being processed.  Check for permissions and raise
  # an exception if the user isn't allowed to delete it.
  def mark_deleted(hub)
    luser = hub.creator # Already original version.
    raise RatingStoneErrors, "#mark_deleted: #{luser.latest_version} not " \
      "allowed to delete record #{self}." unless creator_owner?(luser)

    # All we usually have to do is to set/clear the deleted flag.  Subclasses
    # can override this method if they wish, to do fancier permission checks.
    self.deleted = hub.new_marking_state
    save!
  end

  private

  ##
  # Make sure that the original version of objects are used when saving, since
  # the original ID is what we use to find all versions of an object.  This
  # is mostly a sanity check and may be removed if it's never triggered.
  def validate_link_original_versions_referenced
    errors.add(:unoriginal_parent,
      "Parent isn't the original version: #{parent}") \
      if parent && parent.original_version_id != parent_id

    errors.add(:unoriginal_child,
      "Child isn't the original version: #{child}") \
      if child && child.original_version_id != child_id

    errors.add(:unoriginal_creator,
      "Creator isn't the original version: #{creator}") \
        if creator && creator.original_version_id != creator_id
  end

  ##
  # Automatically approve the end of the link where the creator is the owner or
  # creator of the object at that end of the link.  No fancy checks here for
  # group members etc, that's only in the subclass for things in groups.
  def do_automatic_approvals
    self.approved_parent = true if parent.creator_owner?(creator)
    self.approved_child = true if child.creator_owner?(creator)
  end
end
