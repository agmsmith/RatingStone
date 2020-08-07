# frozen_string_literal: true

class LedgerDelete < LedgerBase
  alias_attribute :reason, :string1
  alias_attribute :context, :string2

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    ledger_count = AuxLedger.where(parent: self).count
    link_count = AuxLink.where(parent: self).count
    "#{ledger_count} Ledger #{'Object'.pluralize(ledger_count)}, " \
      "#{link_count} Link #{'Object'.pluralize(link_count)}"
  end

  ##
  # Class function to delete a list/array/relation of records.  This can include
  # both LedgerBase and LedgerLink records and their subclasses.  A single
  # LedgerDelete record will be created identifying all the records to be
  # deleted (an AuxLedger or AuxLink record will be created for each thing
  # deleted).  Note that all versions of a LedgerBase object are marked deleted
  # no matter which one you specify.  Also only the original LedgerBase record
  # has a AuxLedger record created for it, the other versions are deleted by
  # implication.  luser is the LedgerUser that the deletion will be done by
  # (used for permission checks and assigning blame).  The reason is an optional
  # user provided string explaining why the delete is being done.  Context is a
  # system generated string explaining where the delete comes from.  Returns the
  # LedgerDelete record on success, nil on nothing to do, raises an exception if
  # something goes wrong.
  def self.delete_records(record_collection, luser,
    context = nil, reason = nil)
    add_aux_records(record_collection, luser.original_version,
      context, reason, true)
  end

  ##
  # Internal function that adds the auxiliary records to connect deleted or
  # undeleted things to a LedgerDelete or LedgerUndelete record, as specified
  # by the "do_delete" parameter.  luser is the original version of the user.
  # Returns the LedgerDelete/Undelete record on success, nil on doing nothing,
  # raises a RuntimeError exception (will roll back the whole deletion operation
  # in that case) when something goes wrong.
  private_class_method def self.add_aux_records(record_collection, luser,
    context, reason, do_delete)
    return nil if record_collection.nil? || record_collection.empty?
    ledger_record = nil

    # Make a LedgerDelete or LedgerUndelete object as the hub for the operation,
    # and wrap it in a transaction in case an error exception (such as not
    # having priviledges to delete something) happens.
    ledger_class = do_delete ? LedgerDelete : LedgerUndelete
    ledger_class.transaction do
      ledger_record = ledger_class.new(creator: luser)
      ledger_record.context = context if context
      ledger_record.reason = reason if reason
      ledger_record.save!

      # Copy the records into sets of ID numbers.  That way if someone gave us
      # a relation as input, and deleting items modifies the relation as it is
      # being traversed, we won't get odd behaviour (doubled items etc).  Also
      # being a Set means no duplicates in case someone asked to delete several
      # different versions of an object (we just delete the original and set
      # flags on the others).
      ledger_ids = Set.new
      link_ids = Set.new
      record_collection.each do |a_record|
        if a_record.is_a?(LedgerBase)
          ledger_ids.add(a_record.original_version_id)
        elsif a_record.is_a?(LinkBase)
          link_ids.add(a_record.id)
        else
          logger.warn("#add_aux_records Unknown kind of record: #{a_record}.")
        end
      end
      ledger_ids.each do |an_id|
        a_record = LedgerBase.find(an_id)
        a_record.ledger_delete_append(ledger_record, do_delete)
      end
      link_ids.each do |an_id|
        a_record = LinkBase.find(an_id)
        a_record.ledger_delete_append(ledger_record, do_delete)
      end
    end # End transaction.
    ledger_record
  end
end
