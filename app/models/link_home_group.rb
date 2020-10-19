# frozen_string_literal: true

class LinkHomeGroup < LinkBase
  alias_attribute :user, :parent
  alias_attribute :user_id, :parent_id
  alias_attribute :group, :child
  alias_attribute :group_id, :child_id

  validate :validate_parent_and_child_types
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "Home page of #{parent} is #{child}.".truncate(255)
  end

  def validate_parent_and_child_types
    errors.add(:nonuser, "Parent isn't a user object for #{self}") \
      unless parent.is_a?(LedgerUser)
    errors.add(:nongroup, "Child isn't a full group for #{self}") \
      unless child.is_a?(LedgerFullGroup)
  end
end
