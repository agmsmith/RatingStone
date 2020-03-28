# frozen_string_literal: true

class LinkBase < ApplicationRecord
  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child_ledger, class_name: :LedgerBase, optional: true
  belongs_to :child_link, class_name: :LinkBase, optional: true
  belongs_to :creator, class_name: :LedgerBase, optional: false
end
