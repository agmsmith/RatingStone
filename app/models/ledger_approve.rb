# frozen_string_literal: true

class LedgerApprove < LedgerChangeMarking
  def self.get_marking_method
    :mark_approved # Method to call to approve a LinkBase object.
  end
end
