class LedgerBase < ApplicationRecord
  belongs_to :creator
  belongs_to :original
  belongs_to :amended
  belongs_to :deleted
  belongs_to :ledger1
end
