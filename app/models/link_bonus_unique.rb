# frozen_string_literal: true

###
# Like a LinkBonus, but you can only have one existing (undeleted) at a time.
# Used for bonus points like e-mail activation, where you don't want them to
# activate multiple times.

class LinkBonusUnique < LinkBonus
  validate :validate_uniqueness

  # TODO: Prevent undeleting if some other LinkBonusUnique exists.

  def validate_uniqueness
    return unless LinkBonus.where(parent: parent, child: child,
      deleted: false).where.not(id: id).exists? # Note "id" can be nil.
    errors.add(:validate_uniqueness, "This LinkBonusUnique isn't unique - " \
      "there are other LinkBonus records with the same parent of " \
      "#{parent}.")
  end
end
