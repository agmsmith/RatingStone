# frozen_string_literal: true

class LedgerBase < ApplicationRecord
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

  ##
  # Returns a new Ledger record with a copy of this record's latest version's
  # data (doesn't include cached and calculated data).  Modify it as you will,
  # then when you save it, it will update the original record to point to the
  # newest record as the latest one.  If someone else appended to the ledger
  # first, the save will fail with an error.
  def append_ledger
    new_entry = latest_version.dup
    new_entry.amended_id = nil
    # original_id is copied, now that even the original has its own ID there.
    new_entry.deleted = false
    # Cached values not used (see original record) in amended, set to defaults.
    new_entry.current_down_points = 0.0
    new_entry.current_meh_points = 0.0
    new_entry.current_up_points = 0.0
    new_entry
  end

  ##
  # Finds the original version of this record, which is still used as a central
  # point for the cached calculated values.
  def original_version
    return self if (original_id == id) || original_id.nil?
    original
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
      puts "Bug: some other amended record (#{latest.inspect}) is later than " \
        "this (#{inspect}) new amended record."
      throw(:abort)
    end
    original.update_attribute(:amended_id, id)
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
