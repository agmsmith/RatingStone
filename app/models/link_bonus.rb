# frozen_string_literal: true

class LinkBonus < LinkBase
  alias_attribute :bonus_points, :number1
  alias_attribute :bonus_explanation, :parent
  alias_attribute :bonus_explanation_id, :parent_id
  alias_attribute :bonus_user, :child
  alias_attribute :bonus_user_id, :child_id

  before_create :set_default_description

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child.to_s.truncate(80)} will be getting a " \
      "#{bonus_points} point bonus each week after ceremony " \
      "#{original_ceremony}.  Explanation of bonus is in " \
      "#{parent.to_s.truncate(80)}."
  end

  ##
  # Pre-approve the child by default.  Since this is a system created link,
  # no need for a separate approval step.
  def initial_approval_state
    approvals = super
    approvals[APPROVE_CHILD] = true
    approvals
  end
end
