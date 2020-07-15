# frozen_string_literal: true

class LinkBase < ApplicationRecord
  before_create :do_automatic_approvals
  validate :validate_original_versions_referenced

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
    "#{self.class.name} ##{id} (parent #{approved_parent.to_s[0].upcase}: " \
      "#{parent}, child #{approved_child.to_s[0].upcase}: #{child}, " \
      "number: #{number1}, notes: #{string1})".truncate(255)
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

  ##
  # Return true if the given user is allowed to make changes to the approval of
  # the parent end of this link.  Subclasses may override this.
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
  # Find out who approved me.  Returns a list of LedgerApprove and
  # LedgerUnapprove records, with the most recent first.  Works by searching
  # the AuxLink records for references to this particular record.
  def approved_by
    LedgerBase.joins(:aux_link_downs)
      .where({
        aux_links: { child_id: id },
        type: [:LedgerApprove, :LedgerUnapprove],
      })
      .order(created_at: :desc)
  end

  ##
  # Find out who deleted me.  Returns a list of LedgerDelete and LedgerUndelete
  # records, with the most recent first.  Works by searching the AuxLink
  # records for references to this particular record.
  def deleted_by
    LedgerBase.joins(:aux_link_downs)
      .where({
        aux_links: { child_id: id },
        type: [:LedgerDelete, :LedgerUndelete],
      })
      .order(created_at: :desc)
  end

  ##
  # Internal function to include this record in a bunch being approved or
  # unapproved.  It's linked to a LedgerApprove or LedgerUnapprove record
  # (created by a utility function in the LedgerApprove/Unapprove class) by an
  # AuxLink record (parent field in AuxLink identifies the Ledger(Un)approve)
  # to this record being approved (child field in AuxLink).  If doing an
  # unapprove, the parameter "do_approve" will be false.  Both parent and
  # child are (un)approved if the approver person has permission.  If they
  # don't have any permission, an AuxLink isn't created and an exception thrown.
  def ledger_approve_append(ledger_approve_record, do_approve)
    luser = ledger_approve_record.creator
    changes_permitted = false

    if permission_to_change_parent_approval(luser)
      changes_permitted = true
      self.approved_parent = do_approve
    end

    if permission_to_change_child_approval(luser)
      changes_permitted = true
      self.approved_child = do_approve
    end

    raise RatingStoneErrors, "Not allowed to change any approvals, " \
      "user: #{luser}, record: #{self}." unless changes_permitted

    aux_record = AuxLink.new(parent: ledger_approve_record, child: self)
    aux_record.save!
    save!
    aux_record
  end

  ##
  # Internal function to include this record in a bunch being deleted or
  # undeleted.  Since this is a ledger, it doesn't actually get deleted.
  # Instead, it's linked to a LedgerDelete or LedgerUndelete record (created by
  # a utility function in the LedgerDelete/Undelete class) by an AuxLink
  # record (parent field in AuxLink identifies the Ledger(Un)Delete) to this
  # record being deleted (child field in AuxLink).  If doing an undelete, the
  # parameter "do_delete" will be false.  Returns the AuxLink record or nil
  # or raises an error exception.
  def ledger_delete_append(ledger_delete_record, do_delete)
    # Check for permission to delete a Ledger object.
    luser = ledger_delete_record.creator
    raise RatingStoneErrors,
      "Not allowed to delete record #{self}, user: #{luser}." \
      unless creator_owner?(luser)

    # Make the AuxLink record showing what's being deleted.
    aux_record = AuxLink.new(parent: ledger_delete_record, child: self)
    aux_record.save!
    self.deleted = do_delete
    save!
    aux_record
  end

  private

  ##
  # Make sure that the original version of objects are used when saving, since
  # the original ID is what we use to find all versions of an object.  This
  # is mostly a sanity check and may be removed if it's never triggered.
  def validate_original_versions_referenced
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
    self.approved_parent = true if parent.latest_version.creator_owner?(creator)
    self.approved_child = true if child.latest_version.creator_owner?(creator)
  end
end
