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
  has_many :links_created, class_name: :LinkBase, foreign_key: :creator_id

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
    new_entry.original_ceremony = LedgerAwardCeremony.last_ceremony
    # Cached values not used (see original record) in amended, set to defaults.
    new_entry.deleted = false
    new_entry.expired_now = false
    new_entry.expired_soon = false
    new_entry.has_owners = false
    new_entry.current_down_points = 0.0
    new_entry.current_meh_points = 0.0
    new_entry.current_up_points = 0.0
    new_entry.current_ceremony = -1
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
  # an exception if the user isn't allowed to delete it.  Returns false if
  # nothing was changed.
  def mark_deleted(hub)
    luser = hub.creator # Already original version.
    raise RatingStoneErrors, "#mark_deleted: #{luser.latest_version} not " \
      "allowed to delete record #{self}." unless creator_owner?(luser)

    # All we usually have to do is to set/clear the deleted flag in the
    # original record.  Feature creep would be to delete specific versions of
    # a record; not implemented.  Subclasses can implement more if they wish,
    # such as fancier permission checks.
    if deleted != hub.new_marking_state
      self.deleted = hub.new_marking_state
      save!
      true
    else
      false
    end
  end

  ##
  # Make sure the current_(down|meh|up)_points rating points are up to date.
  # Call this before modifying current points, or even just reading them.
  #
  # Most of the time the points are up to date and this method does nothing
  # quickly.  If the current points are too old, it fades them to catch up with
  # the current time (time is based on award ceremony sequence numbers) and
  # adds in weekly bonus points (mostly for LedgerUsers).
  #
  # If a full recalculation is requested it does a lot more:
  # * Add up the points from all the links referencing this LedgerBase object,
  #   fading each one appropriately by how far in the past it is.
  # * Then removes faded points spent in creating other objects.
  # * Then adds on faded weekly bonus points.
  def update_current_points
    raise RatingStoneErrors,
      "#update_current_points: Not the original version!  #{self}" \
      unless original_version?

    last_ceremony = LedgerAwardCeremony.last_ceremony
    return if current_ceremony >= last_ceremony # Current is still good.

    # Out of date, if just fading is needed then it's fairly simple.

    with_lock do
      # Will be updating our current values so it is a critical section.
      # In case two processes try to update simultaneously, one will get the
      # lock and do the job and the second one that gets the lock later doesn't
      # actually need to do the work.  last_ceremony should remain valid since
      # award ceremonies are done in single tasking mode (web server taken down
      # and job run separately).
      return if current_ceremony >= last_ceremony

      if current_ceremony >= 0 # Just need to fade points to catch up.
        generations = last_ceremony - current_ceremony
        fade_factor = LedgerAwardCeremony::FADE**generations
        self.current_down_points *= fade_factor
        self.current_meh_points *= fade_factor
        self.current_up_points *= fade_factor
        # And add weekly allowance points for the elapsed time.
        update_current_bonus_points_since(current_ceremony, last_ceremony)
      else
        # Recalculation from the beginning has been requested.  The first step
        # is to evaluate reputation points spent on this object by adding up
        # spending received from all undeleted link objects that have this
        # object as a child or as a parent or both (but that's rare).
        # OPTIMIZE: Theoretically we should count ranges of times when the link
        # existed in the past in an undeleted and approved state, but for
        # simplicity we just check the current state.  This could lead to
        # inaccuracies.

        self.current_down_points = 0.0
        self.current_meh_points = 0.0
        self.current_up_points = 0.0

        link_ups.or(link_downs).where(deleted: false).find_each do |a_link|
          # Iterates in batches of 1000.
          generations = last_ceremony - a_link.original_ceremony
          if generations < 0
            # If some future record snuck in, or last_ceremony is out of date
            # then ignore the data.  Shouldn't happen.
            logger.warn("#update_current_points: Ceremony number " \
              "#{a_link.original_ceremony} is in the future, for #{a_link}, " \
              "while updating object #{self}.  Ignoring rating points from " \
              "that future link (check for fraud? recalculate it?).")
            next
          end
          fade_factor = LedgerAwardCeremony::FADE**generations

          if a_link.child_id == id && a_link.approved_child
            amount = a_link.rating_points_boost_child * fade_factor
            case a_link.rating_direction_child
            when "D" then self.current_down_points += amount
            when "M" then self.current_meh_points += amount
            when "U" then self.current_up_points += amount
            end
          end

          if a_link.parent_id == id && a_link.approved_parent
            amount = a_link.rating_points_boost_parent * fade_factor
            case a_link.rating_direction_parent
            when "D" then self.current_down_points += amount
            when "M" then self.current_meh_points += amount
            when "U" then self.current_up_points += amount
            end
          end
        end # find_each

        # Remove points spent in creating links.  Doesn't matter if it's a
        # deleted link, it still counts as spent points for fraud reasons.

        links_created.find_each do |a_link|
          self.current_up_points -= a_link.rating_points_spent
        end

        # And add accumulated faded weekly allowance points for all time.
        update_current_bonus_points_since(original_ceremony, last_ceremony)
      end # full recalculation

      # Check for negative points, a sign of missing records if small,
      # a bug or fraud if large.  Operator should look into it; maybe forcing
      # a full recalculation will fix it.
      #
      # Don't try to automatically fix it; punting negative points into
      # positive points in the opposite category can let you spend more than
      # you have - get a big Up rating, spend it, unapprove the rating, now
      # have negative Up points.  If we changed that into Down points and made
      # Up zero, the user could then re-approve the big Up, and have more Up
      # points to spend.

      if current_down_points < 0.0 || current_meh_points < 0.0 ||
        current_up_points < 0.0
        logger.warn("#update_current_points: Negative rating points " \
          "(#{current_down_points}, #{current_meh_points}, " \
          "#{current_up_points}) in #{self}.  Bug, fraud or deleted old " \
          "records?  Leaving it as is for anti-fraud reasons.")
      end

      self.current_ceremony = last_ceremony
      save!
    end # with_lock
    self
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
      ceremony = LedgerAwardCeremony.last_ceremony
      update_columns(original_id: id,
        original_ceremony: ceremony, current_ceremony: ceremony)
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
  # Adds the effect of other kinds of bonus points on the current points, since
  # the given ceremony number.  Called by update_current_points, with a lock on
  # this object already in effect, will save the record later too.  Subclasses
  # with bonus points should override this method; usually only LedgerUser
  # objects do that.
  def update_current_bonus_points_since(old_ceremony, last_ceremony)
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
