# frozen_string_literal: true

class LinkGroupRoleDelegation < LinkBase
  alias_attribute :delegate_to, :parent
  alias_attribute :delegate_to_id, :parent_id
  alias_attribute :subgroup, :child
  alias_attribute :subgroup_id, :child_id
  validate :validate_parent_and_child_types
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?

    self.string1 = "#{child} is delegating membership " \
      "and other inquires to #{parent}.".truncate(255)
  end

  def validate_parent_and_child_types
    errors.add(:nonfullgroup, "Parent isn't a full group for #{self}") \
      unless delegate_to.is_a?(LedgerFullGroup)
    errors.add(:nonsubgroup, "Child isn't a plain subgroup for #{self}") \
      unless subgroup.is_a?(LedgerSubgroup) &&
        !subgroup.is_a?(LedgerFullGroup)
  end
end
