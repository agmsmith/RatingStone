# frozen_string_literal: true

class LinkHomeGroup < LinkBase
  validate :validate_parent_and_child_types
  before_create :set_default_description

  private

  def set_default_description
    return unless string1.empty?
    self.string1 = "Home page of #{parent} is #{child}.".truncate(255)
  end

  def validate_parent_and_child_types
    errors.add(:nongroup, "Child isn't a full group for #{self}") \
      unless child.is_a?(LedgerFullGroup)
    errors.add(:nonuser, "Parent isn't a user object for #{self}") \
      unless parent.is_a?(LedgerUser)
  end
end
