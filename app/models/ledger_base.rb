# frozen_string_literal: true

##
# General Policies for our API
#
# Return Original Versions:
# Methods that return a versioned object (LedgerBase subclasses) should return
# the original version of that object.  Same for record ID numbers, return the
# ID of the original record, not the latest version.  Only methods that
# explicitly deal with versions should return non-original objects.  The
# general idea is to use the original version as the cannonical version of an
# object, and only access the latest version when displaying data to the user
# or doing a search.
#
# Pass in Any Version:
# Assume the caller passes in any version of an object.  Automatically use the
# original version if processing should be done with canonical objects or IDs.
# Though we assume the record IDs in the database are correctly canonical where
# required.

class LedgerBase < ApplicationRecord
  validate :validate_ledger_original_creator_used,
    :validate_ledger_type_same_between_versions
  after_create :base_after_create

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
    base_string = "##{id} ".dup # dup to unfreeze.
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
    # Cached values not used (see original record) in amended, set to defaults.
    new_entry.deleted = false
    new_entry.expired_now = false
    new_entry.expired_soon = false
    new_entry.has_owners = false
    new_entry.current_down_points = 0.0
    new_entry.current_meh_points = 0.0
    new_entry.current_up_points = 0.0
    new_entry
  end

  ##
  # Finds the original version of this record, which is still used as a central
  # point for the cached calculated values and the canonical representative of
  # the object.  May be slightly faster than just using "original".  Also safer,
  # for that brief moment when original_id is nil since we can't easily have a
  # transaction around record creation (also get a nil original_id in Fixture
  # generated data used for testing and in new unsaved records (id is nil too in
  # that case)).
  def original_version
    return self if original_id.nil? || (original_id == id)
    original
  end

  def original_version?
    original_id.nil? || (original_id == id)
  end

  ##
  # Finds the id number of the original version of this record.  Will be nil if
  # this is an unsaved original record.
  def original_version_id
    return id if original_id.nil?
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
    # Use cached field from database, avoids loading the original record.
    is_latest_version
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
  # stored all in the original ledger record.  Won't work in test mode
  # where original_id is nil for Fixture generated data.
  def all_versions
    LedgerBase.where(original_id: original_version_id).order("created_at")
  end

  ##
  # Returns the current creator of the object.  It's the creator field in the
  # latest version of the object.  Yes, besides adding owners, you can change
  # the creator; needed for handing over full control of a group to a different
  # person.  Also this will be the original version of the creator's record, so
  # check for a later version if you want their current name etc.  Can be nil
  # in an unsaved record.
  def current_creator
    latest_version.creator
  end

  ##
  # Returns the original ID of the current creator of this object.  Or at least
  # it should, if the database is correctly used.  Can be nil in an unsaved
  # record.
  def current_creator_id
    latest_version.creator_id
  end

  ##
  # See if the given user is allowed to delete and otherwise modify this
  # record.  Has to be the current (not necessarily the first) creator or one
  # of the owners of the object.  Returns true if they have permission.
  def creator_owner?(luser)
    raise RatingStoneErrors,
      "#creator_owner?: Need a LedgerUser, not a #{luser} " \
      "object to test against." unless luser.is_a?(LedgerUser)
    luser_original_id = luser.original_version_id
    return true if current_creator_id == luser_original_id

    # Hunt for LinkOwner records that include the mentioned user and this
    # object. Use our original id as key, since we can be using amended
    # versions for data but we want the canonical base version for references.
    # Can save time by skipping the owner search if we know there are no owners.
    my_original = original_version
    return LinkOwner.exists?(parent_id: luser_original_id,
      child_id: my_original.id, deleted: false, approved_parent: true,
      approved_child: true) if my_original.has_owners
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
  # Find out who deleted me.  Returns a list of LedgerDelete records, with the
  # most recent first.  Works by searching the AuxLedger records for references
  # to our original record ID.
  def deleted_by
    LedgerBase.joins(:aux_ledger_downs)
      .where({
        aux_ledgers: { child_id: original_version_id },
        type: [:LedgerDelete],
      })
      .order(created_at: :desc)
  end

  ##
  # Callback method that marks a LedgerBase object as deleted.  Hub record is
  # the LedgerDelete instance being processed.  Check for permissions and raise
  # an exception if the user isn't allowed to delete it.
  def mark_deleted(hub)
    luser = hub.creator # Already original version.
    raise RatingStoneErrors, "#mark_deleted: #{luser.latest_version} not " \
      "allowed to delete record #{self}." unless creator_owner?(luser)

    # All we usually have to do is to set/clear the deleted flag in the
    # original record.  Feature creep would be to delete specific versions of
    # a record; not implemented.  Subclasses can implement more if they wish,
    # such as fancier permission checks.
    self.deleted = hub.new_marking_state
    save!
  end

  ##
  # Recalculate the current rating points if needed (ceremony number isn't
  # current).  Done by adding up the points from all the links referencing
  # this LedgerBase object, fading each one appropriately by how far in the
  # past it is.
  def update_current_points
    last_ceremony = LedgerAwardCeremony.last_ceremony
    return if current_ceremony == last_ceremony

    # Out of date, evaluate reputation points coming from all link objects
    # that have this base object as a child, and points spent by links which
    # have this object as a parent.
    # TODO - write code here for awards ceremony recursive evaluation.

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
  # and do a few things.  Original records need to set their own ID as their
  # original record ID.  Amended records need to update the original to point
  # to them with their ID and fix up the latest record flag.  Sanity check that
  # this is indeed the latest amendment, raise exception if not.
  def base_after_create
    # If this is a record being saved without an original_id, it is an original
    # record itself.  For future queries for all versions convenience, we want
    # original_id to point to self.  Since we can't know the id value until
    # after the save, update original_id after the save.
    if original_id.nil?
      update_columns(original_id: id,
        original_ceremony: LedgerAwardCeremony.last_ceremony)
    else
      # This is a newer version of the record, update pointers back in the
      # original version.  Use a lock to protect the critical section
      # (read and modify amended_id in the original record).
      original.with_lock do
        if original.amended_id != amended_id
          raise RatingStoneErrors,
            "Race condition?  " \
            "Some other amended record (#{original.amended}) " \
            "was added before this (#{self}) new amended record.  " \
            "Original: #{original}"
        end
        # Previous latest one isn't the most recent after this one was created.
        if original.amended
          original.amended.update_attribute(:is_latest_version, false)
        else
          original.update_columns(is_latest_version: false) # Stamped later...
        end
        # We are the latest one now.
        original.update_attribute(:amended_id, id) # Does original's date stamp.
        update_columns(is_latest_version: true) unless is_latest_version
      end
    end
  end

  ##
  # Make sure that the original version of the creator is used when saving.
  # This is mostly a sanity check and may be removed if it's never triggered.
  def validate_ledger_original_creator_used
    return if creator.nil? # You'll get a database NULL exception soon.
    errors.add(:unoriginal_creator, "Creator #{creator} isn't the canonical " \
      "original version.") unless creator.original_version?
  end

  ##
  # Check that the type of a record matches the original version's type.
  # This is mostly a sanity check and may be removed if it's never triggered.
  def validate_ledger_type_same_between_versions
    return if latest_version_id == original_version_id # Only one version.
    errors.add(:type_change_between_versions, "Object #{self} has a " \
      "different type than the original version #{original_version}.") \
      unless type == original_version.type
  end
end
