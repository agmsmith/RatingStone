# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  validates :content, presence: true

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    "#{content.truncate(40)}, " \
      "by: ##{creator_id} #{creator.latest_version.name.truncate(20)}"
  end
end
