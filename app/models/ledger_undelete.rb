# frozen_string_literal: true

class LedgerUndelete < LedgerDelete
  ##
  # Class function to undelete a list of records, see
  # LedgerDelete::delete_records() for docs.
  def self.undelete_records(record_array, delete_user, reason = nil)
    add_aux_records(record_array, delete_user.original_version, reason, false)
  end
end
