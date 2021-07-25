# frozen_string_literal: true

class LedgerApprove < LedgerChangeMarking
  def self.marking_method_name
    :mark_approved # Method to call to approve a LinkBase object.
  end
end
