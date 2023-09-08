# frozen_string_literal: true

require "digest" # For MD5 hash algorithm.

module ApplicationHelper
  include Rails.application.routes.url_helpers # For ledger_base_path()
  include Pagy::Frontend

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
  # Returns an RGB HTML colour code (a # followed by 6 hex characters) for the
  # given input number or string.  Uses an MD5 hash of the input to generate
  # the colour bytes.  Restricts the bytes to a limited range, so you get nicer
  # colours.
  def colour_hash_html(input)
    hash = Digest::MD5.hexdigest(input.to_s).chars
    red = hash[0..1]
    red[0] = half_hex_char(red[0])
    green = hash[2..3]
    green[0] = half_hex_char(green[0])
    blue = hash[4..5]
    blue[0] = half_hex_char(blue[0])
    "#" + red.join + green.join + blue.join
  end

  def half_hex_char(character)
    character.tr("0123456789abcdef", "66778899aabbccdd")
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
