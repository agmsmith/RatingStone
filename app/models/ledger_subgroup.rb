# frozen_string_literal: true

class LedgerSubgroup < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :description, :string2

  # Methods we pass on to the parent LedgerFullGroup(s).
  REDIRECTED_METHODS = %i[can_post? role_test?].to_set

  def to_s
    (super + " (#{name})").truncate(255)
  end

  ##
  # Delegate some operations to the parent LedgerFullGroup(s), if they exist.
  # Returns false if nobody to delegate to or nobody returns true.
  # Look into define_method if this becomes a performance bottleneck.
  def method_missing(method_name, *args, &block)
    if REDIRECTED_METHODS.include?(method_name)
      group_links = LinkGroupRoleDelegation.where(child_id: original_version_id,
        deleted: false)
      group_links.each do |a_link|
        delegate_to = a_link.parent.latest_version
        return true if delegate_to.send(method_name, *args, &block)
      end
      return false
    end

    # Not one of our known redirections, continue with normal handling.
    super
  end

  def respond_to_missing?(method_name, *)
    REDIRECTED_METHODS.include?(method_name) || super
  end
end
