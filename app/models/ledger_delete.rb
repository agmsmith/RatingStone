# frozen_string_literal: true

class LedgerDelete < LedgerChangeMarking
  def self.marking_method_name
    :mark_deleted # Method to call to delete a LinkBase or LedgerBase object.
  end
end
