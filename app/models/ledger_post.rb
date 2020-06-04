# frozen_string_literal: true

class LedgerPost < LedgerBase
  alias_attribute :content, :text1
  validates :content, presence: true
end
