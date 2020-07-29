# frozen_string_literal: true

class LinkSubgroup < LinkBase
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child} is a subgroup of " \
      "#{parent}.".truncate(255)
  end
end
