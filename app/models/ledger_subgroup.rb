# frozen_string_literal: true

class LedgerSubgroup < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :description, :string2

  # Methods we pass on to the parent LedgerFullGroup(s).
  REDIRECTED_METHODS = %i[can_post? permission?].to_set

  ##
  # Delegate some operations to the parent LedgerFullGroup(s), if they exist.
  # Returns false if nobody to delegate to or nobody returns true.
  # Look into define_method if this becomes a performance bottleneck.
  def method_missing(method_name, *args, &block)
    puts "Bleeble in LedgerSubgroup missing method."
    if REDIRECTED_METHODS.include?(method_name)
      group_links = LinkGroupRoleDelegation.where(child_id: original_version_id,
        deleted: false)
      group_links.each do |a_link|
        if a_link.parent.is_a?(LedgerFullGroup)
          return true if a_link.parent.send(method_name, *args, &block)
        else
          logger.warn("#{a_link.parent.class.name} ##{a_link.parent.id} is " \
            "not a LedgerFullGroup.  Corrupted data?  Referenced by " \
            "#{a_link.class.name} ##{a_link.id}.")
        end
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
