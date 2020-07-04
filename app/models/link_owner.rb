# frozen_string_literal: true

class LinkOwner < LinkBase
  alias_attribute :owner, :parent
  alias_attribute :thing, :child
end
