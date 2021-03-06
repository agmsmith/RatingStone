# frozen_string_literal: true

class LedgerBase < ApplicationRecord
  validate :validate_ledger_original_versions_referenced
  after_save :patch_original_id # Do this one first - lower level field init.
  after_create :my_after_create

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
  # Return a user readable description of the object.  Besides some unique
  # identification so we can find it in the database, have some readable
  # text so the user can guess which object it is (like the content of a post).
  # Usually used in error messages, which the user may see.  Format is
  # record ID[s], class name, (optional context text in brackets).
  # Max 255 characters.
  def to_s
    base_string = base_s
    extra_info = context_s
    base_string << " (#{extra_info})" unless extra_info.empty?
    base_string.truncate(255)
  end

  ##
  # Return a basic user readable identification of an object (ID and class).
  # Though ID can be nil for unsaved new records.
  def base_s
    base_string = "##{id} ".dup # dup to unfreeze, silly for #{} strings.
    if original_version.amended_id
      base_string << "[#{original_version_id}-#{latest_version_id}] "
    end
    base_string + self.class.name
  end

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages and debugging.
  # Empty string for none.
  def context_s
    ""
  end

  ##
  # Returns a new Ledger record with a copy of this record's latest version's
  # data (doesn't include cached and calculated data).  Modify it as you will,
  # then when you save it, it will update the original record to point to the
  # newest record as the latest one.  If someone else appended to the ledger
  # first, the save will fail with an exception.  No permissions checks done,
  # should usually test if the user doing this is creator_owner?
  def append_version
    new_entry = latest_version.dup
    new_entry.original_id = original_version_id # In case original_id is nil.
    new_entry.amended_id = original_version.amended_id # For consistency check.
    new_entry.deleted = false
    # Cached values not used (see original record) in amended, set to defaults.
    new_entry.has_owners = false
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
  # get a nil original_id in Fixture generated data used for testing and in
  # new unsaved records (id is nil too in that case)).
  def original_version
    return self if id.nil? || original_id.nil? || (original_id == id)
    original
  end

  ##
  # Finds the id number of the original version of this record.
  def original_version_id
    return original_id if id.nil? # Partial save has original_id but id is nil.
    return id if original_id.nil? || (original_id == id)
    original_id
  end

  ##
  # Finds the latest version of this record (could be a deleted one).  Note
  # that non-ledger fields (cached calculated values like rating points) are
  # stored elsewhere, in the original ledger record.  However, the content and
  # the creator are most up to date in this latest version record.
  def latest_version
    latest = original_version.amended
    return latest unless latest.nil?
    self # We are the only and original version.
  end

  ##
  # Returns true if this record is the latest version.
  def latest_version?
    is_latest_version # Use cached value, avoids looking up original record.
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
    LedgerBase.where(original_id: original_version_id).order("created_at")
  end

  ##
  # Returns the current creator of the object.  It's the creator field in the
  # latest version of the object.  Yes, besides adding owners, you can change
  # the creator; needed for handing over full control of a group to a different
  # person.  Also this will be the latest version of the creator's record, so
  # you get their current name etc.
  def current_creator
    latest_version.creator.latest_version
  end

  ##
  # Returns the original ID of the current creator of this object.  Or at least
  # it should, if the database is correctly used.  Nil for unsaved new records.
  def current_creator_id
    latest_version.creator_id
  end

  ##
  # See if the given user is allowed to delete and otherwise modify this
  # record.  Has to be the current (not necessarily original) creator or the
  # owner of the object.  Returns true if they have permission.
  def creator_owner?(luser)
    raise RatingStoneErrors,
      "Need a LedgerUser, not a #{luser.class.name} " \
      "object to test against." unless luser.is_a?(LedgerUser)
    luser_original_id = luser.original_version_id
    return true if current_creator_id == luser_original_id

    # Hunt for LinkOwner records that include the mentioned user and this
    # object. Use our original id as key, since we can be using amended
    # versions for data but we want the canonical base version for references.
    # Can save time by skipping the owner search if we know there are no owners.
    return LinkOwner.exists?(parent_id: luser_original_id,
      child_id: original_version_id, deleted: false, approved_parent: true,
      approved_child: true) if original_version.has_owners
    false
  end

  ##
  # Returns true if the given user is allowed to view the object.  Needs to be
  # creator/owner, or a group reader if it is a group, or a group reader of a
  # group that the test object is in.  If the object is in multiple groups, the
  # user just has to be a group reader in one of them.
  def allowed_to_view?(luser)
    return true if creator_owner?(luser)
    return role_test?(luser, LinkRole::READER) if is_a?(LedgerSubgroup)
    # Test the user's status in groups for things (content) attached to groups.
    if is_a?(LedgerContent)
      LinkGroupContent.where(child_id: original_version_id, deleted: false,
        approved_parent: true, approved_child: true).each do |a_link|
        return true if a_link.group.role_test?(luser, LinkRole::READER)
      end
    end
    false
  end

  ##
  # Find out who deleted me.  Returns a list of LedgerDelete and LedgerUndelete
  # records, with the most recent first.  Works by searching the AuxLedger
  # records for references to our original record ID.
  def deleted_by
    LedgerBase.joins(:aux_ledger_downs)
      .where({
        aux_ledgers: { child_id: original_version_id },
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
    luser = ledger_delete_record.creator # Already original version.
    raise RatingStoneErrors, "#{luser} not allowed to delete record " \
      "#{self}." unless creator_owner?(luser)
    aux_record = AuxLedger.new(parent: ledger_delete_record,
      child_id: original_version_id)
    aux_record.save!

    # Note update_all goes direct to the database, so callbacks and timestamps
    # won't be used/updated.  Instead iterate through records to update.  Or we
    # could use update_all and also set the updated_at date.
    LedgerBase.where(original_id: original_version_id).order("created_at")
      .each do |x|
      x.deleted = do_delete
      x.save!
    end
    aux_record
  end

  ##
  # Recalculate the current rating points if needed (ceremony number isn't
  # current).  Done by adding up the points from all the links referencing
  # this LedgerBase object, fading each one appropriately by how far in the
  # past it is.
  # 
  def update_current_points
    last_ceremony = LedgerAwardCeremony.last_ceremony
    return if current_ceremony == last_ceremony

    # Out of date, evaluate reputation points coming from all link objects
    # that have this base object as a child, and points spent by links which
    # have this object as a parent.
    # bleeble

    missing_generations = if current_ceremony < 0
      last_ceremony # TODO: current_ceremony needs recompution using date stamp.
    else
      last_ceremony - current_ceremony
    end
    return current_ceremony if missing_generations <= 0
    factor = LedgerAwardCeremony::FADE**missing_generations
    self.current_down_points *= factor
    self.current_meh_points *= factor
    self.current_up_points *= factor
    self.current_ceremony = last_ceremony
    save!
    current_ceremony
  end

  private

  ##
  # If this is an amended ledger record, now that it has been created, go back
  # and do a few things.  Update the original record to point to the newly
  # saved amended data.  Sanity check that this is indeed the latest amendment,
  # raise exception if not.
  #
  # Remember to call this from subclasses with an after_create of their own.
  def my_after_create
    # Wrap this critical section (read and modify amended_id) in a transaction.
    self.class.transaction do
      if original.amended_id != amended_id
        raise RatingStoneErrors,
          "Race condition?  Some other amended record (#{original.amended}) " \
          "was added before this (#{self}) new amended record.  " \
          "Original: #{original}"
      end
      # Previous latest one isn't the most recent any more.
      if original.amended
        original.amended.update_attribute(:is_latest_version, false)
      else
        original.update_columns(is_latest_version: false) # Stamped later...
      end
      # We are the latest one now.
      original.update_attribute(:amended_id, id) # Does date stamp for original.
      update_columns(is_latest_version: true)
    end
  end

  ##
  # Make sure that the original version of objects are used when saving, since
  # the original ID is what we use to find all versions of an object.  This
  # is mostly a sanity check and may be removed if it's never triggered.
  def validate_ledger_original_versions_referenced
    errors.add(:unoriginal_creator,
      "Creator #{creator.class.name} ##{creator_id} isn't the original " \
      "version.") if creator && creator.original_version_id != creator_id
  end

  ##
  # Patch the original_id if needed.  If this is a record being saved without
  # an original_id, it is an original record itself.  For future queries for
  # all versions convenience, we want original_id to point to self.  Since we
  # can't know the id value until after the save, update original_id after the
  # save.  Also as a side effect, fixes Fixture created records which don't
  # run callbacks when they're created, but do when they're changed.
  def patch_original_id
    return unless original_id.nil?
    update_columns(original_id: id) # Doing "save" here would be recursive!
  end
end
