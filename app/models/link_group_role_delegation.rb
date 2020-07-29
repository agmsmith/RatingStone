# frozen_string_literal: true

class LinkGroupRoleDelegation < LinkBase
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child} is delegating membership " \
      "and other inquires to #{parent}.".truncate(255)
  end
end
