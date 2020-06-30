# frozen_string_literal: true

class LedgerFullGroup < LedgerSubgroup
  # Extra group properties too big to fit here are in a GroupSetting record.
  has_one :group_setting, dependent: :destroy, autosave: true
end
