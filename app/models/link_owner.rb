# frozen_string_literal: true

class LinkOwner < LinkBase
  alias_attribute :owner, :parent
  alias_attribute :thing, :child

  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child} is an owner of #{parent}.".truncate(255)
  end
end
