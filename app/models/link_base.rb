# frozen_string_literal: true

class LinkBase < ApplicationRecord
  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
  belongs_to :creator, class_name: :LedgerBase, optional: false

  has_many :aux_link_ups, class_name: :AuxLink, foreign_key: :child_id
  has_many :aux_link_ancestors, through: :aux_link_ups, source: :parent

  ##
  # Internal function to include this record in a bunch being deleted or
  # undeleted.  Since this is a ledger, it doesn't actually get deleted.
  # Instead, it's linked to a LedgerDelete or LedgerUndelete record (created by
  # a utility function in the LedgerDelete/Undelete class) by an AuxLink
  # record (parent field in AuxLink identifies the Ledger(Un)Delete) to this
  # record being deleted (child field in AuxLink).  If doing an undelete, the
  # parameter "deleting" will be false.
  def ledger_delete_append(ledger_delete_record, deleting)
    aux_record = AuxLink.new(parent: ledger_delete_record, child: self)
    aux_record.save
    update_attribute(:deleted, deleting)
  end

  ##
  # Find out who deleted me.  Returns a list of LedgerDelete and LedgerUndelete
  # records, with the most recent first.  Works by searching the AuxLink
  # records for references to this particular record.
  def deleted_by
    LedgerBase.joins(:aux_link_descendants)
      .where({
        aux_links: { child_id: id },
        type: [:LedgerDelete, :LedgerUndelete],
      })
      .order(created_at: :desc)
  end
end
