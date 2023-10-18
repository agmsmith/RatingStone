# frozen_string_literal: true

require_relative "ledger_change_marking.rb"

class LedgerApprove < LedgerChangeMarking
  class << self
    def marking_method_name
      :mark_approved # Method to call to approve a LinkBase object.
    end
  end
end
