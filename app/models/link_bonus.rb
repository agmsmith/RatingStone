# frozen_string_literal: true

class LinkBonus < LinkBase
  alias_attribute :bonus_points, :float1
  alias_attribute :bonus_explanation, :parent
  alias_attribute :bonus_explanation_id, :parent_id
  alias_attribute :bonus_user, :child
  alias_attribute :bonus_user_id, :child_id
  alias_attribute :reason, :string1
  alias_attribute :expiry_ceremony, :number1

  before_create :set_default_description, :check_expiry_ceremony

  def set_default_description
    return unless string1.empty?

    self.string1 = "Bonus of #{bonus_points} points every ceremony after but " \
      "not including ceremony ##{original_ceremony} up to but not including " \
      "ceremony ##{expiry_ceremony}."
  end

  ##
  # The approval or deletion state has changed.  Add (if add is true) or remove
  # the accumulated bonuses from the user.  Assume we are called only after the
  # deletion or approval state changes in a way that changes the bonus.  The
  # caller will lock and then save the bonus_user (aka child) record for us.
  def add_or_remove_bonus(add)
    current_ceremony = LedgerAwardCeremony.last_ceremony
    return if original_ceremony >= current_ceremony # Bonus not active yet.

    if expiry_ceremony >= current_ceremony
      generations_fade = 0 # Bonus hasn't expired yet.
      generations_bonus = current_ceremony - original_ceremony
    else # Bonus has expired, and faded a bit.
      generations_fade = current_ceremony - expiry_ceremony
      generations_bonus = expiry_ceremony - original_ceremony
    end

    # Note that zero or negative generations means no bonus.  Usually happens
    # in first week when the bonus doesn't take effect yet, or a far future one.
    return if generations_bonus <= 0

    bonus_change = bonus_points *
      LedgerAwardCeremony.accumulated_bonus(generations_bonus) *
      LedgerAwardCeremony::FADE**generations_fade
    bonus_change = -bonus_change unless add
    bonus_user.current_meh_points += bonus_change
  end

  def check_expiry_ceremony
    return if expiry_ceremony.nil? ||
      expiry_ceremony > LedgerAwardCeremony.last_ceremony

    raise RatingStoneErrors,
      "#check_expiry_ceremony: Expiry ceremony isn't in future, for #{self}."
  end
end
