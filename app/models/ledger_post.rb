# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  validates :content, presence: true
end
