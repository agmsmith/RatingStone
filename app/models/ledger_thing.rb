# frozen_string_literal: true

##
# A class for representing objects in the real world.  Like a book.  Actual
# type of thing is set by the classification groups it is in.
class LedgerThing < LedgerBase
  alias_attribute :name, :string1
  validates :name, presence: true, length: { maximum: 255 }

  ##
  # Return some user readable context for the object.  Used in error messages.
  def context_s
    "representing \"#{name.truncate(40).tr("\n", ' ')}\""
  end
end
