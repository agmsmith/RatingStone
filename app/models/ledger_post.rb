# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1

  validates :content, presence: true
  # Have to repeat these validations for subclasses.  Ugh!
  validates :subject, presence: true, length: { maximum: 255 }
  validates :summary_of_changes, length: { maximum: 255 }
end
