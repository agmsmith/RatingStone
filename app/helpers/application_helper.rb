# frozen_string_literal: true

module ApplicationHelper
  # Returns the full web page title with an optional per-page subtitle.
  def full_title(page_title = '')
    base_title = "Rating Stone"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end
end
