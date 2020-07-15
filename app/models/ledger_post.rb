# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  validates :content, presence: true

  def to_s
    (super + " (by: ##{creator_id} " \
      "#{creator.latest_version.name.truncate(20)}, " \
      "#{content.truncate(40)})").truncate(255)
  end
end
