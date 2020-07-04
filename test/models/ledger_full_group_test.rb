# frozen_string_literal: true

require 'test_helper'

class LedgerFullGroupTest < ActiveSupport::TestCase
  def setup
    @group = LedgerFullGroup.new(name: "T Group",
      description: "Group for Testing", creator_id: 0)
    @settings = @group.build_group_setting
    @group.save
  end
end
