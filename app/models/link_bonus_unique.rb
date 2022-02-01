# frozen_string_literal: true

###
# Like a LinkBonus, but you can only have one existing (undeleted) at a time.
# Used for bonus points like e-mail activation, where you don't want them to
# activate multiple times.

class LinkBonusUnique < LinkBonus
  validate :validate_uniqueness

  ##
  # Check that we aren't making this object active (undeleted and approved)
  # when there is another equivalent LinkBonus that is already active.
  def mark_approved(hub)
    if !deleted && hub.new_marking_state
      if duplicate_linkbonus_exists?
        raise RatingStoneErrors, "#mark_approved: Some other LinkBonus is " \
          "active when trying to approve record #{self}."
      end
    end
    super
  end

  ##
  # Check that we aren't making this object active (undeleted and approved)
  # when there is another equivalent LinkBonus that is already active.
  def mark_deleted(hub)
    if approved_parent && approved_child && !hub.new_marking_state
      if duplicate_linkbonus_exists?
        raise RatingStoneErrors, "#mark_deleted: Some other equivalent " \
          "LinkBonus is active when trying to undelete record #{self}."
      end
    end
    super
  end

  def validate_uniqueness
    return unless duplicate_linkbonus_exists?
    errors.add(:validate_uniqueness, "Creating a LinkBonusUnique which isn't " \
      "unique - there are other LinkBonus records with the same parent of " \
      "#{parent} and child #{child}.")
  end

  private

  ##
  # Returns true if there is some other active LinkBonus or subclasses record
  # that is similar to this one.  Note that self.id can be nil for newly
  # created but unsaved records, and that works correctly.
  def duplicate_linkbonus_exists?
    LinkBonus.where(parent: parent, child: child, deleted: false,
      approved_parent: true, approved_child: true).where.not(id: id).exists?
  end
end
