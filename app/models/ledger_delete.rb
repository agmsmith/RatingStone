# frozen_string_literal: true

class LedgerDelete < LedgerBase
  alias_attribute :reason, :string1

  ##
  # Class function to delete a list of records.  This can include both
  # LedgerBase and LedgerLink records and their subclasses.  A single
  # LedgerDelete record will be created identifying all the records to be
  # deleted (an AuxLedger or AuxLink record will be created for each thing
  # deleted).  Delete_user is the LedgerUser that the deletion will be done by
  # (used for permission checks and assigning blame). The reason is an optional
  # string explaining why the delete is being done.  Returns the LedgerDelete
  # record or nil on failure.
  def self.delete_records(record_array, delete_user, reason = nil)
    return nil if record_array.nil? || record_array.empty?
    return nil if delete_user.nil?
    ledger_delete = LedgerDelete.new(creator: delete_user)
    ledger_delete.reason = reason if reason
    ledger_delete.save
    record_array.each do |a_record|
      a_record.ledger_delete_append(ledger_delete)
    end
    ledger_delete
  end
end
