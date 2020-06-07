# frozen_string_literal: true

class LinkBase < ApplicationRecord
  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
  belongs_to :creator, class_name: :LedgerBase, optional: false

  has_many :aux_link_ups, class_name: :AuxLink, foreign_key: :child_id
  has_many :aux_link_ancestors, through: :aux_link_ups, source: :parent

  ##
  # Internal function to include this record in a bunch being deleted.  Since
  # this is a ledger, it doesn't actually get deleted.  Instead, it's linked to
  # a LedgerDelete record (created by a utility function in the LedgerBase
  # class) by an AuxLink record (parent field in AuxLink identifies the
  # LedgerDelete) to this record being deleted (child field in AuxLink,
  # points to this record).
  def ledger_delete_append(ledger_delete_record)
    aux_record = AuxLink.new(parent: ledger_delete_record, child: self)
    aux_record.save
    update_attribute(:deleted, true)
  end
end
