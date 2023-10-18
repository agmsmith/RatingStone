# frozen_string_literal: true

require_relative "application_record.rb"

class GroupSetting < ApplicationRecord
  belongs_to :ledger_full_group, class_name: :LedgerBase, optional: false
end
