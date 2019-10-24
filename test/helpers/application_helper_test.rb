# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal full_title, "Rating Stone"
    assert_equal full_title("Help"), "Help | Rating Stone"
  end
end
