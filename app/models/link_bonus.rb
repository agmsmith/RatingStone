# frozen_string_literal: true

class LinkBonus < LinkBase
  alias_attribute :bonus_points, :number1
  alias_attribute :bonus_explanation, :parent
  alias_attribute :bonus_explanation_id, :parent_id
  alias_attribute :bonus_user, :child
  alias_attribute :bonus_user_id, :child_id
  alias_attribute :reason, :string1

  before_create :set_default_description

  def set_default_description
    return unless string1.empty?
    self.string1 = "Bonus of #{bonus_points} points after ceremony " \
      "##{original_ceremony}."
  end

  ##
  # The approval or deletion state has changed.  Add (if add is true) or remove
  # the accumulated bonuses from the user.  Assume we are called only after the
  # deletion or approval state changes in a way that changes the bonus.  The
  # caller will save the bonus_user record for us.
  def add_or_remove_bonus(generations, add)
    bonus_change = bonus_points *
      LedgerAwardCeremony.accumulated_bonus(generations)
    bonus_change = -bonus_change unless add
    bonus_user.current_meh_points += bonus_change
  end
end
