# frozen_string_literal: true

class Clip < ApplicationRecord
  belongs_to :ledger_user, class_name: :LedgerBase, optional: false
  belongs_to :ledger_object, class_name: :LedgerBase, optional: true
  belongs_to :link_object, class_name: :LinkBase, optional: true
end
