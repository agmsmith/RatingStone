# frozen_string_literal: true

class LedgerUnapprove < LedgerApprove
  ##
  # Class function to unapprove a list of LinkBase records, see
  # LedgerApprove::approve_records() for docs.
  def self.unapprove_records(record_collection, luser,
    context = nil, reason = nil)
    add_aux_records(record_collection, luser.original_version,
      context, reason, false)
  end
end
