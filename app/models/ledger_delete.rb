# frozen_string_literal: true

class LedgerDelete < LedgerChangeMarking
  def self.get_marking_method
    :mark_deleted # Method to call to delete a LinkBase or LedgerBase object.
  end
end
