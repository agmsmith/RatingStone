# frozen_string_literal: true

class LinkBase < ApplicationRecord
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
end
