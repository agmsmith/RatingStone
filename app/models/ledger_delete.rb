# frozen_string_literal: true

class LedgerDelete < LedgerBase
  alias_attribute :reason, :string1

  ##
  # Class function to delete a list of records.  This can include both
  # LedgerBase and LedgerLink records and their subclasses.  A single
  # LedgerDelete record will be created identifying all the records to be
  # deleted (an AuxLedger or AuxLink record will be created for each thing
  # deleted).  Note that all versions of a LedgerBase object are marked deleted
  # no matter which one you specify (should specify only one otherwise it will
  # double delete things, wasting database space).  Also only the original
  # LedgerBase record has a AuxLedger record created for it, the other versions
  # are deleted by implication.  Delete_user is the LedgerUser that the deletion
  # will be done by (used for permission checks and assigning blame).
  # The reason is an optional string explaining why the delete is being done.
  # Returns the LedgerDelete record or nil on failure or throws a database
  # error (will roll back everything in that case).
  def self.delete_records(record_array, delete_user, reason = nil)
    add_aux_records(record_array, delete_user, reason, true)
  end

  ##
  # Internal function that adds the auxiliary records to connect deleted or
  # undeleted things to a LedgerDelete or LedgerUndelete record, as specified
  # by the "deleting" parameter.
  private_class_method def self.add_aux_records(record_array, user, reason,
    deleting = true)
    return nil if record_array.nil? || record_array.empty?
    return nil if user.nil?
    ledger_record = nil
    ledger_class = deleting ? LedgerDelete : LedgerUndelete
    ledger_class.transaction do
      ledger_record = ledger_class.new(creator: user)
      ledger_record.reason = reason if reason
      ledger_record.save
      record_array.each do |a_record|
        a_record.ledger_delete_append(ledger_record, deleting)
      end
    end
    ledger_record
  end
end
