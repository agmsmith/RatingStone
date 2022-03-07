# frozen_string_literal: true

module ApplicationHelper
  include Rails.application.routes.url_helpers # For ledger_base_path()

  # Returns the full web page title with an optional per-page subtitle.
  def full_title(page_title = "")
    base_title = "Rating Stone"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  ##
  # Return an HTML string showing the rating points of a LedgerObject.
  def points_html(lobject)
    result = ""
    if lobject.current_up_points != 0
      result += format("^%.2f ", lobject.current_up_points)
    end
    if lobject.current_meh_points != 0
      result += format("~%.2f ", lobject.current_meh_points)
    end
    if lobject.current_down_points != 0
      result += format("v%.2f ", lobject.current_down_points)
    end
    result.strip!
    result = "~" if result.empty?
    result
  end

  ##
  # Return an HTML string showing the creation time of a LedgerObject, and the
  # estimated expiry time.  Has a link to the raw object too.
  def timestamp_html(lobject)
    ("<span class=\"timestamp\">#{points_html(lobject)} " \
    "<a href=\"#{ledger_base_path(lobject)}\">##{lobject.id}</a> " \
    "created #{time_ago_in_words(lobject.created_at)} ago&nbsp;- <small>" \
    "#{lobject.created_at.getlocal}.  " + (lobject.expiry_time <= Time.now ?
    "Expired." : "Expires in #{time_ago_in_words(lobject.expiry_time)}.") +
    "</small></span>").html_safe
  end
end
