# frozen_string_literal: true

class LinkSubgroup < LinkBase
  alias_attribute :parent_group, :parent
  alias_attribute :parent_group_id, :parent_id
  alias_attribute :sub_group, :child
  alias_attribute :sub_group_id, :child_id

  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "#{child} is a subgroup of " \
      "#{parent}.".truncate(255)
  end
end
