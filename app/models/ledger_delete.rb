# frozen_string_literal: true

require_relative "ledger_change_marking.rb"

class LedgerDelete < LedgerChangeMarking
  class << self
    def marking_method_name
      :mark_deleted # Method to call to delete a LinkBase or LedgerBase object.
    end
  end
end
