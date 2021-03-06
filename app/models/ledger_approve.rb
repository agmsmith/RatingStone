# frozen_string_literal: true

class LedgerApprove < LedgerBase
  alias_attribute :reason, :string1
  alias_attribute :context, :string2

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    ledger_count = AuxLedger.where(parent: self).count
    link_count = AuxLink.where(parent: self).count
    "#{ledger_count} Ledger #{"Object".pluralize(ledger_count)}, " \
      "#{link_count} Link #{"Object".pluralize(link_count)}"
  end

  ##
  # Class function to approve a bunch of link records.  Each end of the link
  # that the user has permission to approve will be approved.  A single
  # LedgerApprove record will be created identifying all the records to be
  # approved (an AuxLink record will be created for each thing approved).
  # luser is the LedgerUser that the approval will be done by (used for
  # permission checks and assigning blame).  The reason is an optional
  # user provided string explaining why the approval is being done.  Context is
  # a system generated string explaining where the approval comes from.  Returns
  # the LedgerApprove record on success, raises an exception if no changes were
  # made (failed approval - user doesn't have permission to give approval) or
  # something else goes wrong.  Nil returned if no records passed in.
  def self.approve_records(record_collection, luser,
    context = nil, reason = nil)
    add_aux_records(record_collection, luser.original_version,
      context, reason, true)
  end

  ##
  # Internal function that adds the auxiliary records to connect approved or
  # unapproved things to a LedgerApprove or LedgerUnapprove record, as specified
  # by the "do_approve" parameter.  luser is the original version of the user.
  # Returns the LedgerApprove/Unapprove record on success, raises a RuntimeError
  # exception (will roll back the whole approval operation in that case) when
  # something goes wrong (including lack of permission to make approvals).
  private_class_method def self.add_aux_records(record_collection, luser,
    context, reason, do_approve)
    return nil if record_collection.nil? || record_collection.empty?
    ledger_record = nil

    # Make a LedgerApprove or LedgerUnapprove object as the hub.
    ledger_class = do_approve ? LedgerApprove : LedgerUnapprove
    ledger_class.transaction do
      ledger_record = ledger_class.new(creator: luser)
      ledger_record.context = context if context
      ledger_record.reason = reason if reason
      ledger_record.save!

      record_collection.each do |a_record|
        a_record.ledger_approve_append(ledger_record, do_approve)
      end
    end
    ledger_record
  end
end
