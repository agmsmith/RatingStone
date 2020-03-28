# frozen_string_literal: true

class AuxLedger < ApplicationRecord
  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
end
