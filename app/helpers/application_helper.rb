# frozen_string_literal: true

module ApplicationHelper
  include Rails.application.routes.url_helpers # For ledger_base_path()

  ##
  # Various variations (user preference) on some standard labels for things.
  # RELATED: Also update users/_name_email_password_form.html.erb
  DIRECTION_LABELS = {
    "U" => ["Up ", "^", "👍 "], # Note space after sometimes, style dependent.
    "M" => ["Meh ", "~", "🤏 "],
    "D" => ["Down ", "v", "👎 "],
    "R" => ["Reply", "R", "🗩"],
    "Q" => ["Quote", "Q", "“”"],
  }

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
  # Return an HTML string formatted to show a single point value and its
  # direction ("U", "M", "D"), displayed in the style preferred by the current
  # user.  Usually used for showing single point values in Links.
  def point_html(direction, points)
    label_style = current_user&.fancy_labels
    label_style = 0 if label_style.nil? || label_style < 0
    label_style = 2 if label_style > 2

    DIRECTION_LABELS[direction][label_style] + format("%.2f", points)
  end

  ##
  # Return an HTML string showing the rating points of a LedgerObject,
  # displayed in the style preferred by the current user.  Not done in a View
  # since it's also used for link text in the header.
  def points_html(lobject)
    lorig = lobject.original_version # Points are stored in the original.
    result = ""

    # Labels for the points have a style: 0 for ASCII words to label things
    # like Up/Meh/Down, Reply, Quote when displaying them to this user.
    # 1 for short ASCII like ^~v for up/meh/down.  2 for UTF font icons
    # or emoji.
    label_style = current_user&.fancy_labels
    label_style = 0 if label_style.nil? || label_style < 0
    label_style = 2 if label_style > 2

    if lorig.current_up_points != 0
      result += DIRECTION_LABELS["U"][label_style] +
        format("%.2f", lorig.current_up_points)
    end
    if lorig.current_meh_points != 0
      result += " / " unless result.empty?
      result += DIRECTION_LABELS["M"][label_style] +
        format("%.2f", lorig.current_meh_points)
    end
    if lorig.current_down_points != 0
      result += " / " unless result.empty?
      result += DIRECTION_LABELS["D"][label_style] +
        format("%.2f", lorig.current_down_points)
    end
    result = result.strip
    result = "~" if result.empty?
    result.html_safe
  end
end
