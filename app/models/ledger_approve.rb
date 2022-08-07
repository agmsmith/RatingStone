# frozen_string_literal: true

class LedgerApprove < LedgerChangeMarking
  class << self
    def marking_method_name
      :mark_approved # Method to call to approve a LinkBase object.
    end
  end
end
