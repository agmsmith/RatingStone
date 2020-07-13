# frozen_string_literal: true

class LinkBase < ApplicationRecord
  before_create :do_automatic_approvals
  before_save :check_original_versions_referenced

  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
  belongs_to :creator, class_name: :LedgerBase, optional: false

  has_many :aux_link_ups, class_name: :AuxLink, foreign_key: :child_id
  has_many :aux_link_ancestors, through: :aux_link_ups, source: :parent

  ##
  # See if the given user is allowed to delete and otherwise modify this record.
  # Has to be the creator of the object.  Returns true if they have permission.
  def creator_owner?(ledger_user)
    raise RatingStoneErrors,
      "Need a LedgerUser, not a #{ledger_user.class.name} " \
      "object to test against." unless ledger_user.is_a?(LedgerUser)
    ledger_user_id = ledger_user.original_version_id
    return true if creator_id == ledger_user_id
    false
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
  # Internal function to include this record in a bunch being deleted or
  # undeleted.  Since this is a ledger, it doesn't actually get deleted.
  # Instead, it's linked to a LedgerDelete or LedgerUndelete record (created by
  # a utility function in the LedgerDelete/Undelete class) by an AuxLink
  # record (parent field in AuxLink identifies the Ledger(Un)Delete) to this
  # record being deleted (child field in AuxLink).  If doing an undelete, the
  # parameter "do_delete" will be false.
  def ledger_delete_append(ledger_delete_record, do_delete)
    luser = ledger_delete_record.creator.latest_version # Get most recent name.
    raise RatingStoneErrors, "#{luser.class.name} ##{luser.id} " \
      "(#{luser.name}) not allowed to delete #{type} ##{id}." unless
      creator_owner?(luser)
    aux_record = AuxLink.new(parent: ledger_delete_record, child: self)
    aux_record.save
    update_attribute(:deleted, do_delete)
  end

  private

  ##
  # Make sure that the original version of objects are used when saving, since
  # the original ID is what we use to find all versions of an object.  This
  # is mostly a sanity check and may be removed if it's never triggered.
  def check_original_versions_referenced
    raise RatingStoneErrors,
      "Parent #{parent.class.name} ##{parent.id} isn't the original version." \
      if parent.original_version_id != parent.id

    raise RatingStoneErrors,
      "Child #{child.class.name} ##{child.id} isn't the original version." \
      if child.original_version_id != child.id
  end

  ##
  # Automatically approve the end of the link where the creator is the owner or
  # creator of the object at that end of the link.
  def do_automatic_approvals
    self.approved_parent = true if parent.latest_version.creator_owner?(creator)
    self.approved_child = true if child.latest_version.creator_owner?(creator)
  end
end
