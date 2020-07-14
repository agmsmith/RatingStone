# frozen_string_literal: true

class LedgerBase < ApplicationRecord
  validate :validate_original_versions_referenced
  after_save :patch_original_id # Do this one first - lower level field init.
  after_save :amend_original_record

  # Always have a creator, but "optional: false" makes it reload the creator
  # object every time we do something with an object.  So just require it to
  # be non-NULL in the database definition.
  belongs_to :creator, class_name: :LedgerBase, optional: true

  belongs_to :original, class_name: :LedgerBase, optional: true
  belongs_to :amended, class_name: :LedgerBase, optional: true

  has_many :link_downs, class_name: :LinkBase, foreign_key: :parent_id
  has_many :descendants, through: :link_downs, source: :child
  has_many :link_ups, class_name: :LinkBase, foreign_key: :child_id
  has_many :ancestors, through: :link_ups, source: :parent

  has_many :aux_ledger_downs, class_name: :AuxLedger, foreign_key: :parent_id
  has_many :aux_ledger_descendants, through: :aux_ledger_downs, source: :child
  has_many :aux_ledger_ups, class_name: :AuxLedger, foreign_key: :child_id
  has_many :aux_ledger_ancestors, through: :aux_ledger_ups, source: :parent
  has_many :aux_link_downs, class_name: :AuxLink, foreign_key: :parent_id
  has_many :aux_link_descendants, through: :aux_link_downs, source: :child

  ##
  # Returns a new Ledger record with a copy of this record's latest version's
  # data (doesn't include cached and calculated data).  Modify it as you will,
  # then when you save it, it will update the original record to point to the
  # newest record as the latest one.  If someone else appended to the ledger
  # first, the save will fail with an error.
  def append_ledger
    new_entry = latest_version.dup
    new_entry.amended_id = nil
    new_entry.original_id = original_version_id # In case original_id is nil.
    new_entry.deleted = false
    # Cached values not used (see original record) in amended, set to defaults.
    new_entry.current_down_points = 0.0
    new_entry.current_meh_points = 0.0
    new_entry.current_up_points = 0.0
    new_entry
  end

  ##
  # Finds the original version of this record, which is still used as a central
  # point for the cached calculated values.  May be slightly faster than just
  # using "original".  Also safer, for that brief moment when original_id is
  # nil since we can't easily have a transaction around record creation (also
  # get a nil original_id in Fixture generated data used for testing).
  def original_version
    return self if (original_id == id) || original_id.nil?
    original
  end

  ##
  # Finds the id number of the original version of this record.
  def original_version_id
    return id if (original_id == id) || original_id.nil?
    original_id
  end

  ##
  # Finds the latest version of this record (could be a deleted one).  Note
  # that non-ledger fields (cached calculated values like rating points) are
  # stored elsewhere, in the original ledger record.
  def latest_version
    latest = original_version.amended
    return latest unless latest.nil?
    self # We are the only and original version.
  end

  ##
  # Finds the id of the latest version of this record.
  def latest_version_id
    latest_id = original_version.amended_id
    return latest_id unless latest_id.nil?
    id # We are the only and original version.
  end

  ##
  # Finds all versions of this record (including deleted ones).  Returned in
  # increasing date order (thus original version is first, we assume).  Note
  # that non-ledger fields (cached calculated values like rating points) are
  # stored elsewhere, in the original ledger record.  Won't work in test mode
  # where original_id is nil for Fixture generated data.
  def all_versions
    LedgerBase.where(original_id: original_version_id).order('created_at')
  end

  ##
  # See if the given user is allowed to delete and otherwise modify this
  # record.  Has to be the creator or the owner of the object.  Returns
  # true if they have permission.  Be careful if you're testing an older/newer
  # version of this object where the creator has changed (best to ask for the
  # latest version of the object to do the test against to get the current
  # creator).
  def creator_owner?(ledger_user)
    raise RatingStoneErrors,
      "Need a LedgerUser, not a #{ledger_user.class.name} " \
      "object to test against." unless ledger_user.is_a?(LedgerUser)
    ledger_user_id = ledger_user.original_version_id
    return true if creator_id == ledger_user_id

    # Hunt for LinkOwner records that include the mentioned user and this
    # object. Use the original_id as key, since we can be using amended
    # versions for data but we want the canonical base version for references.
    LinkOwner.exists?(parent_id: ledger_user_id, child_id: original_version_id)
  end

  ##
  # Return true if the user has permission to do the things implied by the role.
  # Since this is a plain object, it delegates to a group if it can.
  def permission?(luser, test_role)
    # Creator has all permissions.
    return true if creator_id == luser.original_version_id

    # If looking for the owner.
    if creator_owner?(luser)
      return true if test_role <= LinkRole::OWNER
    end

    # See if we are linked to a group by a LinkGroupContent record.
    LedgerBase.joins(:link_downs)
      .where({
        link_bases: { child_id: original_version_id, type: :LinkGroupContent },
      }).each do |a_group|
      return true if a_group.permission?(luser, test_role)
    end
    false
  end

  ##
  # Find out who deleted me.  Returns a list of LedgerDelete and LedgerUndelete
  # records, with the most recent first.  Works by searching the AuxLedger
  # records for references to this particular record and also to the original
  # record if this one is a later version (theoretically don't have to do that).
  def deleted_by
    deleted_ids = [id]
    deleted_ids.push(original_version_id) if id != original_version_id
    LedgerBase.joins(:aux_ledger_downs)
      .where({
        aux_ledgers: { child_id: deleted_ids },
        type: [:LedgerDelete, :LedgerUndelete],
      })
      .order(created_at: :desc)
  end

  ##
  # Internal function to include this record in a bunch being deleted or
  # undeleted.  Since this is a ledger, it doesn't actually get deleted.
  # Instead, it's linked to a LedgerDelete or LedgerUndelete record (created by
  # a utility function in the LedgerDelete/Undelete class) by an AuxLedger
  # record (parent field in AuxLedger identifies the Ledger(Un)Delete) to this
  # record being deleted (child field in AuxLedger, points to the original
  # version of this record).  If doing an undelete, the parameter "do_delete"
  # will be false.  All versions of this record will also be marked
  # as (un)deleted.  In the future we may mark individual versions as being
  # deleted, if that's useful.  Returns the AuxLedger record if successful.
  def ledger_delete_append(ledger_delete_record, do_delete)
    luser = ledger_delete_record.creator
    raise RatingStoneErrors, "#{luser.class.name} ##{luser.id} " \
      "(#{luser.latest_version.name}) not allowed to delete " \
      "#{type} ##{id}." unless creator_owner?(luser)
    aux_record = AuxLedger.new(parent: ledger_delete_record,
      child_id: original_version_id)
    aux_record.save!
    # Note update_all goes direct to the database, so callbacks and timestamps
    # won't be used/updated.  Would have to iterate through records to do that.
    LedgerBase.where(original_id: original_version_id)
      .update_all(deleted: do_delete)
    aux_record
  end

  private

  ##
  # If this is an amended ledger record, once it has been saved, go back and
  # update the original record to point to the newly saved amended data.  Check
  # that this is indeed the latest amendment by date, fail if it is not.
  def amend_original_record
    return if (original_id == id) || original_id.nil?
    # Verify that there are no later amended version records than this one.
    latest = LedgerBase.where(original_id: original_id).order('created_at').last
    if latest.id != id
      logger.error("Bug: some other amended record (#{latest.inspect}) is " \
        "later than this (#{inspect}) new amended record."
      throw(:abort) # Stop the ActiveRecord transaction.
    end
    original.update_attribute(:amended_id, id)
  end

  ##
  # Make sure that the original version of objects are used when saving, since
  # the original ID is what we use to find all versions of an object.  This
  # is mostly a sanity check and may be removed if it's never triggered.
  def validate_original_versions_referenced
    errors.add(:unoriginal_creator,
      "Creator #{creator.class.name} ##{creator.id} isn't the original " \
      "version.") if creator && creator.original_version_id != creator.id
  end

  ##
  # Patch the original_id if needed.  If this is a record being saved without
  # an original_id, it is an original record itself.  For future queries for
  # all versions convenience, we want original_id to point to self.  Since we
  # can't know the id value until after the save, update original_id after the
  # save.
  def patch_original_id
    return unless original_id.nil?
    update_attribute(:original_id, id) # Doing "save" here would be recursive!
  end
end
