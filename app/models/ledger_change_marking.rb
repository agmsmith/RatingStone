# frozen_string_literal: true

class LedgerChangeMarking < LedgerBase
  alias_attribute :reason, :string1
  alias_attribute :context, :string2
  alias_attribute :new_marking_state, :bool1

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    ledger_count = AuxLedger.where(parent_id: original_version_id).count
    link_count = AuxLink.where(parent_id: original_version_id).count
    "#{ledger_count} Ledger #{"Object".pluralize(ledger_count)}, " \
      "#{link_count} Link #{"Object".pluralize(link_count)}"
  end

  ##
  # Class function that returns a symbol with the name of the method to call on
  # an object to mark it.  Subclasses will override this to specify the
  # operations they do.  So LedgerDelete class will return :mark_deleted,
  # LedgerApprove class will return :mark_approved.  The marking code will then
  # call that method on each object (LedgerBase and/or LinkBase subclass
  # instances) being marked, with a boolean flag argument specifying the desired
  # new marking state.
  def self.get_marking_method
    :mark_not_implemented_for_base_class_ledger_change_marking
  end

  ##
  # Class function to mark a list/array/relation of records.  This can include
  # both LedgerBase and LedgerLink records and their subclasses.  A single
  # LedgerChangeMarking record (usually a subclass like LedgerDelete) will be
  # created identifying all the records to be marked (an AuxLedger or AuxLink
  # record will be created for each thing marked).  Note that all versions of a
  # LedgerBase object are marked no matter which one you specify.  Also only
  # the original LedgerBase record has a AuxLedger record created for it, the
  # other versions are marked by implication.  luser is the LedgerUser that the
  # deletion will be done by (used for permission checks and assigning blame).
  # The reason is an optional user provided string explaining why the delete is
  # being done.  Context is a system generated string explaining where the
  # delete comes from.  Returns the LedgerChangeMarking record on success, nil
  # on nothing to do, raises an exception if something goes wrong.
  def self.mark_records(record_collection, new_marking_state, luser,
    context = nil, reason = nil)
    return nil if record_collection.nil? || record_collection.empty?

    creator_user = luser.original
    raise RatingStoneErrors,
      "#mark_records: Wrong type of input, #{luser} (original version) " \
      "should be a LedgerUser." unless creator_user.is_a?(LedgerUser)

    # Method name to actually do the marking work depends on our class.
    marking_method_symbol = self.get_marking_method

    # Create a LedgerChangeMarking (usually a subclass like LedgerDelete)
    # instance as the hub for the operation, and wrap it in a transaction in
    # case an error exception (such as not having priviledges to delete
    # something) happens.
    self.transaction do
      hub_record = self.new(creator_id: creator_user.id)
      hub_record.context = context if context
      hub_record.reason = reason if reason
      hub_record.new_marking_state = new_marking_state
      hub_record.save!

      # Copy the records into sets of ID numbers.  That way if someone gave us
      # a relation as input, and deleting items modifies the relation as it is
      # being traversed, we won't get odd behaviour (doubled items etc).  Also
      # being a Set means no duplicates in case someone asked to delete several
      # different versions of an object (we just delete the original).
      ledger_ids = Set.new
      link_ids = Set.new
      record_collection.each do |a_record|
        if a_record.is_a?(LedgerBase)
          ledger_ids.add(a_record.original_version_id)
        elsif a_record.is_a?(LinkBase)
          link_ids.add(a_record.id)
        else
          logger.error("#mark_records Unknown kind of record: #{a_record}.")
        end
      end
      ledger_ids.each do |an_id|
        a_record = LedgerBase.find(an_id)
        AuxLedger.create!(parent_id: hub_record.id, child_id: an_id)
        a_record.send(marking_method_symbol, new_marking_state)
      end
      link_ids.each do |an_id|
        a_record = LinkBase.find(an_id)
        AuxLink.create!(parent_id: hub_record.id, child_id: an_id)
        a_record.send(marking_method_symbol, new_marking_state)
      end
    end # End transaction.
    hub_record
  end
end
