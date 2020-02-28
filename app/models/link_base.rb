# frozen_string_literal: true

class LinkBase < ApplicationRecord
  belongs_to :parent, class_name: :LedgerBase, optional: false
  belongs_to :child, class_name: :LedgerBase, optional: false
  belongs_to :creator, class_name: :LedgerBase, optional: false
  belongs_to :deleted, class_name: :LedgerBase, optional: true
end
