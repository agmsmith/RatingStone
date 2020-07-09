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
  # Returns the LedgerDelete record on success, nil on nothing to do, raises
  # an exception if something goes wrong.
  def self.delete_records(record_array, delete_user, reason = nil)
    add_aux_records(record_array, delete_user.original_version, reason, true)
  end

  ##
  # Internal function that adds the auxiliary records to connect deleted or
  # undeleted things to a LedgerDelete or LedgerUndelete record, as specified
  # by the "do_delete" parameter.  Returns the LedgerDelete/Undelete record on
  # success, nil on doing nothing, raises a RuntimeError exception (will roll
  # back everything in that case) when something goes wrong.
  private_class_method def self.add_aux_records(record_array, luser,
    reason, do_delete = true)
    return nil if record_array.nil? || record_array.empty?
    ledger_record = nil
    ledger_class = do_delete ? LedgerDelete : LedgerUndelete
    ledger_class.transaction do
      ledger_record = ledger_class.new(creator: luser)
      ledger_record.reason = reason if reason
      ledger_record.save
      record_array.each do |a_record|
        a_record = a_record.original_version if a_record.is_a?(LedgerBase)
        a_record.ledger_delete_append(ledger_record, do_delete)
      end
    end
    ledger_record
  end
end
