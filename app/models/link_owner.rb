# frozen_string_literal: true

require_relative "link_base.rb"

class LinkOwner < LinkBase
  alias_attribute :owner, :parent
  alias_attribute :owner_id, :parent_id
  alias_attribute :thing, :child
  alias_attribute :thing_id, :child_id

  validate :validate_parent_type

  before_create :set_default_description
  after_create :set_has_owner_in_child

  private

  def set_default_description
    return unless string1.empty?

    self.string1 = "#{owner} is an owner of #{thing}.".truncate(255)
  end

  def set_has_owner_in_child
    thing.update_attribute(:has_owners, true)
  end

  def validate_parent_type
    errors.add(:nonuser, "Owner object needs to be a LedgerUser for #{self}") \
      unless owner.is_a?(LedgerUser)
  end
end
