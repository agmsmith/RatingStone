# frozen_string_literal: true

require 'numbers_in_words'
require 'diffy'

# Controller and model (it's just a string and this is a quickie coding project)
# too.  It expands numbers and some other things in the way that someone reading
# them aloud would do.  The number of words in the expanded submitted text is
# then counted.  Voice-over artists find this useful for estimating the true
# time to read some text aloud.  Or you could use an AI driven text to speech
# service to do the same thing.  Anyway, Dane Scott of TuneTrackerSystems is
# doing voice-over work and suggested this project.  AGMS20201130

class WordCounterController < ApplicationController

  skip_before_action :verify_authenticity_token
  # Also could do "protect_from_forgery with: :null_session".
  # Turn off cross site forgery detection, no password or permanent data
  # saving is done in this page.  It serves only to annoy users when they
  # try loading an old page and refreshing it (such as when the server has
  # been rebooted).  Revisit this if we require a log-in.

  EXPANSION_SYMBOLS = [ # In alphabetical order for easier manual additions.
    :exp_atsignletter, :exp_atsignnumber, :exp_comma_space, :exp_dash_to_to,
    :exp_dollars, :exp_hashtag, :exp_hyphens,
    :exp_leadingohs, :exp_leadingzeroes, :exp_na_telephone,
    :exp_number_of, :exp_numbers, :exp_numbers_and, :exp_numbers_dash,
    :exp_percent, :exp_say_area_code, :exp_say_telephone_number,
    :exp_slash_per_always, :exp_slash_per_number, :exp_slash_slash_always,
    :exp_urls, :exp_years
  ]

  def update
    @vo_script = params[:vo_script]
    @selected_expansions = Hash.new(false)
    if @vo_script
      # Use an empty script if Clear button pressed, otherwise remove the blank
      # line that the Form textarea adds at front, depending on the browser.
      @vo_script = params[:commit] == 'Clear' ? '' : @vo_script.strip

      # Copy known expansion settings to our local storage.  If a checkbox
      # isn't checked then the param is missing rather than false.
      EXPANSION_SYMBOLS.each do |a_symbol|
        @selected_expansions[a_symbol] = true if params[a_symbol]
      end
    else # First time run, use some demo text and default settings.
      @vo_script = <<~DEFAULTSCRIPT
        To start - click Clear and paste your script in here, replacing this example.

        Some examples (and test cases we haven't implemented yet):

        URLs - Uniform Resource Locators
        Visit https://user:password@ratingstone.agmsmith.ca/server01/about/
        for more information or search on www.google.com
        (https://www.google.ca/search?hl=en-CA&q=Real+Count) for hints/tips or
        write to the sysop @ agmsrepsys@gmail.com.  Get the files from
        ftp://anonymous:password@example.com/public/
        Note that happy@home doesn't get expanded.

        Telephone numbers:
        Give us a call at 1-800-JKLHYDE (1-800-555-4933), or (613) 555 7648,
        or locally it's 555-7648.  555-1234x432 specifies an extension, as does
        1-222-555-1234 ext. 1234 or even 555-1234 extension 5432.  In all cases
        the extension number is read as separate digits.  But 9876543210 is
        just a number (add dashes or spaces to make it a telephone number).
        211, 311,… 911 are special cases.

        Comma Space:
        Add a space, after commas inside words.  This,or that.  But doesn't
        affect the word count.  1,2 since comma is okay without spaces inside
        a number.

        Dashed - Numbers:
        From 1920-30 a dash between two numbers becomes "to".  Even
        $1.2 — $2.50 are expanded.  A long work day runs from 9 ⸻ 5.  But
        not - between words.  We handle all these dashes in case you
        somehow type them in: - ‐ ‑ ‒ – — ⸺ ⸻ ﹘ ﹣ －

        At-signs before words.
        On Facebook @RealCount is #1 in the category!  But @ is not expanded
        with a space after it.  Also Needs@ a space before it.  Doit@now!
        should not change.  By the way, e-mails like someone@gmail.com are
        handled by URL expansion.

        At-signs before numbers and dollars.
        3@$0.75 is a good price.  Almost like buying 2 @ 35 cents each.  Sell
        coal@12 1/8.

        Percent after a Number:
        That's a 40-50% savings!  50 % more with a space after it. %x x% aren't
        numbers.  Save 50%each.

        # Hashtag:
        Look for #theanswer where the # is before a word and there is a space
        in front, so middle#hash or just # won't get expanded.

        # Number:
        Look for #22 or # 123 where the # is before the number.
        99# doesn't expand, same as a#9.

        / to per for numbers:
        Expand a slash to "per", but only if it's got a number at one end
        (not both; that would be a fraction).  He makes 3 door mats/hour.
        Try some A/B testing.  3 l/100km and 50 miles/gallon.  But not 3/4.
        Eggs @ $2.35 / dozen.  Or one egg / $ 0.20.  That's 5 eggs/$1.

        / to per always:
        Expand a slash to "per" in all remaining situations.
        A/B, 9/A, A / 9, 9 / 9, 3/4.

        / to slash always:
        Expand a slash to "slash" in all remaining situations.
        A/B, 9/A, A / 9, 9 / 9, 3/4.

        Dollars and cents.
        Save $1,234.56 on word-costs, @$1.125/word.  Fractional
        dollars like coal @ $ 12.125 are handled too.  $.12ea currently doesn't
        work (rarely seen it in real life, except that one time, use $0.12ea).
        And $9.99 million needs to be manually fixed up (otherwise we'd need
        an AI to figure out the context). # $9 leaves # alone.  Price set
        to$4each (adds spaces if needed).

        4 digit dates:
        Save on word-costs in 2020, compared to 1990's fees.  Much better than
        in the 1950s!  Notice that 50s and other decades aren't handled (yet).
        Is 1930 a date… or a military time?  Also note special wording for first
        ten years in a century and millenia:
        1000, 1009, 1066, 1803, 1900, 1901, 1920, 2000, 2001, 2009, 2010, 2099.

        Leading zero numbers:
        But call before 2020.12.07 at 6:01 a.m. (that's December 7th, 2020,
        0601 military time) or try in the evening at 1930.  We're also open
        from 8a.m. to 7:05pm on Saturdays.  Note that 1201, 4.01 or 2,011
        isn't expanded since there is a number before the 01 or near it with
        a comma or period in the way.

        Numbers, commas and minus signs:
        Only -1,234.56 seconds remain before this offer expires!  Can
        optionally remove the "and" in long numbers and the - dash between
        some number words.

        Dashes between Words:
        Remove dashes directly between words (no spaces).  Voice-over,
        twenty‐three, hot‑dog, hyper‒text, tele–phone, foot—ball,
        game⸺pad, yet⸻more, cauli﹘flower, the﹣end, finally－done.  Though
        9⸺pad, yet⸻8, 7﹘6 and so -on- don't get converted (also see dashed
        numbers).

        Ellipsis - not yet implemented:
        Maybe….. try calling us in the evening.   ...or not.

        Metric units dictionary - not yet implemented.
        Our pool heater can heat 3m3 per minute, of water with a density of 1.0 g/cm3, increasing the temperature by 5C with 20,000W of energy (1.3kg/h of natural gas).  With 5cm diamater (19.63cm2 cross sectional area), that's a 8km/h flow speed.

        English units dictionary - not yet implemented.
        The pool heater raises the water temperature by 10-15F, at 20GPM (1.5 hp motor), which uses 150,000 BTU/hour from burning logs.  With 2" pipes (32' long), it's flowing at 5 mph.
      DEFAULTSCRIPT

      EXPANSION_SYMBOLS.each do |a_symbol|
        @selected_expansions[a_symbol] = true
      end
      @selected_expansions[:exp_numbers_and] = false
      @selected_expansions[:exp_numbers_dash] = false
      @selected_expansions[:exp_say_area_code] = false
      @selected_expansions[:exp_say_telephone_number] = false
      @selected_expansions[:exp_slash_per_always] = false
      @selected_expansions[:exp_slash_slash_always] = false
    end

    # Spaces to avoid edge conditions.  Three spaces so "9" at very end can have
    # three characters after it for the st, th, rd plus space test.
    @expanded_script = '   ' + @vo_script + '   '

    # Order of operations here is significant.
    expand_urls if @selected_expansions[:exp_urls]
    expand_na_telephone if @selected_expansions[:exp_na_telephone]
    expand_comma_space if @selected_expansions[:exp_comma_space]
    expand_dash_to_to if @selected_expansions[:exp_dash_to_to]
    expand_at_sign_letter if @selected_expansions[:exp_atsignletter]
    expand_at_sign_number if @selected_expansions[:exp_atsignnumber]
    expand_percent if @selected_expansions[:exp_percent]
    expand_hashtag if @selected_expansions[:exp_hashtag]
    expand_number_of if @selected_expansions[:exp_number_of]
    expand_slash_per_number if @selected_expansions[:exp_slash_per_number]
    expand_slash_per_always if @selected_expansions[:exp_slash_per_always]
    expand_slash_slash_always if @selected_expansions[:exp_slash_slash_always]
    expand_dollars if @selected_expansions[:exp_dollars]
    expand_years if @selected_expansions[:exp_years]
    expand_leading_zeroes if @selected_expansions[:exp_leadingzeroes]
    expand_numbers if @selected_expansions[:exp_numbers]
    expand_hyphens if @selected_expansions[:exp_hyphens]

    @expanded_script.strip! # Remove edge case workaround spaces, for display.

    # Calculate some statistics on the words.

    words = word_split(@vo_script.downcase)
    @original_word_count = words.length
    @original_word_list = Hash.new(0)
    words.sort.each do |word|
      @original_word_list[word] += 1
    end

    words = word_split(@expanded_script.downcase)
    @expanded_word_count = words.length
    @expanded_word_list = Hash.new(0)
    words.sort.each do |word|
      @expanded_word_list[word] += 1
    end

    # Subtract counts of original words from counts of expanded words, so we
    # can see how the count changed.
    @hybrid_word_list = @expanded_word_list.dup
    @original_word_list.each do |key, value|
      @hybrid_word_list[key] -= value
    end

    logger.info("  #{@original_word_count} word script expanded to " \
      "#{@expanded_word_count} words " \
      "(#{@expanded_word_count - @original_word_count} extra).")

    render
  end

  private

  # Break the given string into an array of strings, one word in each.  Words
  # are separated by spaces, or by commas when the commas are not inside a
  # number.  Also strip punctuation from the beginning and end of the words.
  def word_split(input_string)
    # Add spaces after commas if none there, except for commas in numbers.
    spaced = input_string
      .gsub(/([^[[:space:]]]),([^[[:digit:]][[:space:]]])/, "\\1, \\2")
      .gsub(/([^[[:space:]][[:digit:]]]),([^[[:space:]]])/, "\\1, \\2")
    result = []
    spaced.split(/[[:space:]]+/).each do |a_word|
      depunct = a_word.sub(/^[,.?"“”!()]+/, '').sub(/[,.?"“”!()]+$/, '')
      result.append(depunct) unless depunct.empty? # Happens for "..."
    end
    result
  end

  def remove_and_dash(input_text)
    # The user has the option to remove the word "and" and the - in numbers
    # read as words.  So "one hundred and one" becomes "one hundred one",
    # and "twenty-one" becomes "twenty one".  The default NumbersInWords
    # processing adds them.  The user has options to turn on or off those
    # removals.
    output_text = input_text
    unless @selected_expansions[:exp_numbers_and]
      output_text = output_text.gsub(/ and /, ' ')
    end
    unless @selected_expansions[:exp_numbers_dash]
      output_text = output_text.gsub(/([[:alpha:]])-([[:alpha:]])/, "\\1 \\2")
    end
    output_text
  end

  # Various methods for expanding things.  Input and output is @expanded_script.

  def expand_at_sign_letter
    # An @ with a space in front and a letter immediately afterwards becomes
    # "at-sign".  @Twitter becomes: at-sign Twitter
    re = %r{(?<spacebefore>[[:space:]])
      @ # The at sign we're looking for.
      (?<letterafter>[[:alpha:]]) # Require a letter to start the next word.
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:spacebefore] + 'at-sign' + ' ' +
        result[:letterafter]
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_at_sign_number
    # An @ with a number or dollar sign somewhere afterwards becomes
    # "at".  Stock@$9.25 becomes: Stock at $9.25
    re = %r{
      (?<spacebefore>[[:space:]]?) # Optional space before.
      @ # The at sign we're looking for.
      (?<spaceafter>[[:space:]]*) # Optional space after.
      (?<letterafter>[[[:digit:]]$]) # Require a number or dollar for the next word.
      }x
    while (result = re.match(@expanded_script))
      expanded_text = if result[:spacebefore].nil? || result[:spacebefore].empty?
        ' '
      else
        result[:spacebefore]
      end
      expanded_text += 'at' +
        if result[:spaceafter].nil? || result[:spaceafter].empty?
          ' '
        else
          result[:spaceafter]
        end
      expanded_text += result[:letterafter]
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_urls
    # Extract a whole URL from the text then apply several processing steps to
    # it then put the expanded version back.  Needs to work for
    # https://www.example.com/stuff/more/ and for mit.edu but not 2.3 or p.m.
    # or one/two.
    re = %r{
      (?<spacebefore>[[[:space:]]\(\"]) #")) Space etc. before the URL required.
      (?<http>[[:alpha:]]+://)? # Optional HTTP:// or HTTPS:// or FTP:// prefix.
      (?<middle>[[:alpha:]] # No initial digit allowed, start with a letter.
        [[:alnum:]]+ # Finish the first word, 2 or more letters.
        ([@:][[:alnum:]][[:alnum:]]+)* # Password, userid, but no slash dot.
        ([.][[:alnum:]][[:alnum:]]+) # www Dot com or such.  Dot required.
        ([.:/_\-?=%&+][[:alnum:]]+)* # Rest of the separators and words.
        /?) # Optional trailing slash.
      (?<spaceafter>[[[:space:]][[:punct:]]]) # Ends with space or punctuation.
    }xi # x for ignore spaces in definition, i for case insensitive.
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match + result[:spacebefore] +
        (result[:http] ? result[:http].gsub(%r{://}, " colon slash slash ") : '') +
        result[:middle]
          .gsub(/\./, ' dot ').gsub(%r{/}, ' slash ')
          .gsub(/@/, ' at ').gsub(/:/, ' colon ')
          .gsub(/_/, ' underscore ').gsub(/-/, ' dash ')
          .gsub(/\?/, ' question mark ').gsub(/=/, ' equals ')
          .gsub(/%/, ' percent ').gsub(/&/, ' ampersand ')
          .gsub(/\+/, ' plus ').strip +
        result[:spaceafter] + result.post_match
    end
  end

  # Convert a string number to individual digits.  "0123" becomes
  # "zero one two three", not "one two three" or "one hundred and twenty three".
  def number_to_digits(number_string)
    expanded_text = ''
    number_string.each_char do |digit|
      expanded_text += NumbersInWords.in_words(digit.to_i) + ' '
    end
    expanded_text.strip # Remove trailing space if any.
  end

  # Given an area code number as a string, say it as digits unless it's an even
  # hundred, then say it as a hundreds number.  So it's "eight hundred" rather
  # than "eight zero zero".  Common for "one eight hundred" toll free numbers.
  def area_code_to_words(area_code_string)
    if area_code_string[-2..-1] == '00'
      NumbersInWords.in_words(area_code_string.to_i)
    else
      number_to_digits(area_code_string)
    end
  end

  def expand_na_telephone
    # Look for telephone numbers and convert them to digit by digit words.
    # North American numbers look like 1-800-123-4567 for a long distance
    # number, or 1 (800) 222-4567 or 800-222-4567 or 800 222-4567 or
    # (800) 222-4567 or 613 555-1234 or just 222-4567 for a local number.
    # The area code is 3 digits from 200 to 999.  Similarly the exchange number
    # in the middle is also from 200 to 999.  For details, see Wikipedia's
    # NANP article # https://en.wikipedia.org/wiki/North_American_Numbering_Plan
    # 911 and other one one numbers are a special case.  If followed by
    # x, ext, ext., extension and a number, that number will be read out
    # digit by digit.
    # If @selected_expansions[:exp_say_area_code] is true then the words
    # "area code" are inserted before the area code if there is one.  To have
    # it say "telephone number" before the last seven digits part, set
    # @selected_expansions[:exp_say_telephone_number] to true.
    re = %r{(?<spacebefore>[[:space:]])
      (((?<leadingone>1)([-‐‑‒–—⸺⸻﹘﹣－]|[[:space:]]+))?
      (\(?(?<areacode>[2-9][0-9][0-9])([-‐‑‒–—⸺⸻﹘﹣－]|(\)?[[:space:]]+))))?
      (?<exchange>[2-9][0-9][0-9])([-‐‑‒–—⸺⸻﹘﹣－]|[[:space:]])
      (?<number>[0-9][0-9][0-9][0-9])
      ([[:space:]]*(x|ext\.?|extension)[[:space:]]*(?<extension>[0-9]+))?
      (?<spaceafter>[[[:space:]][[:punct:]]]) # Ends with space or punctuation.
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:spacebefore]
      expanded_text += number_to_digits(result[:leadingone]) + ' ' if result[:leadingone]
      if result[:areacode]
        expanded_text += 'area code ' if @selected_expansions[:exp_say_area_code]
        expanded_text += area_code_to_words(result[:areacode]) + ' '
      end
      expanded_text += 'telephone number ' if @selected_expansions[:exp_say_telephone_number]
      expanded_text += number_to_digits(result[:exchange]) + ' ' +
        number_to_digits(result[:number])
      if result[:extension]
        expanded_text += ' extension ' + number_to_digits(result[:extension])
      end
      expanded_text += result[:spaceafter]

      @expanded_script = result.pre_match + expanded_text + result.post_match
    end

    # Handle 911 and other "one one" numbers.
    re = %r{
      (?<before>[[:space:]])
      (?<number>[2-9]11)
      (?<after>[[[:space:]][[:punct:]]])
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:before]
      expanded_text += 'telephone number ' if @selected_expansions[:exp_say_telephone_number]
      expanded_text += number_to_digits(result[:number])
      expanded_text += result[:after]

      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_hyphens
    # Replace hyphens with spaces.  Need to have letters on both sides of the
    # hyphen to avoid clobbering minus signs and other hyphen uses.
    re = /(?<letter1>[[:alpha:]])[-‐‑‒–—⸺⸻﹘﹣－](?<letter2>[[:alpha:]])/
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match + result[:letter1] + ' ' +
        result[:letter2] + result.post_match
    end
  end

  def expand_percent
    # A % sign after a number is expanded to the word "percent".
    # 12% becomes: 12 percent.  Can have space so "13 %." becomes "13 percent."
    re = %r{(?<digitbefore>[[:digit:]]) # Starts with a digit.
      (?<spacebefore>[[:space:]]*) # Optional spaces between digit and %.
      % # The percent sign.
      (?<letterafter>[^[[:space:]][[:punct:]]]?) # Stuff after needs distance?
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:digitbefore] +
        if result[:spacebefore].nil? || result[:spacebefore].empty?
          ' '
        else
          result[:spacebefore]
        end
      expanded_text += "percent"
      if result[:letterafter] && !result[:letterafter].empty?
        expanded_text += ' ' + result[:letterafter]
      end
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_hashtag
    # A # sign with a space before and a letter afterwards expands to
    # "hashtag".  #RealWordCount becomes: hashtag RealWordCount
    re = %r{(?<spacebefore>[[:space:]])
      \# # The octothorpe number sign.
      (?<letterafter>[[:alpha:]])
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:spacebefore] + 'hashtag ' + result[:letterafter]
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_number_of
    # A #sign before number is expanded to the word "number".
    # #12 becomes: number 12.  Can have space so "# 13." becomes "number 13."
    re = %r{(?<spacebefore>[[:space:]]) # Need a space before the #.
      \# # The octothorpe number sign.
      (?<interspace>[[:space:]]*) # Optional spaces between # and digit.
      (?<digitafter>[[:digit:]]) # Ends with a digit.
      }x
    while (result = re.match(@expanded_script))
      expanded_text = result[:spacebefore] + 'number' +
        if result[:interspace].nil? || result[:interspace].empty?
          ' '
        else
          result[:interspace]
        end
      expanded_text += result[:digitafter]
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_slash_per_number
    # Expand / to "per" if there is a number on just one side.
    re = %r{(
      (?<thingbefore>[[:digit:]])
        [[:space:]]*
        /
        [[:space:]]*
        (?<thingafter>[^[[:digit:]]$[[:space:]]])
      )|(
        (?<thingbefore>[^[[:digit:]][[:space:]]])
        [[:space:]]*
        /
        [[:space:]]*
        (?<thingafter>[[[:digit:]]$])
      )}x
    while (result = re.match(@expanded_script))
      before = result[:thingbefore]
      after = result[:thingafter]
      @expanded_script = result.pre_match +
        before + (/[[:space:]]\Z/.match(before) ? '' : ' ') +
        'per' +
        (/\A[[:space:]]/.match(after) ? '' : ' ') + after +
        result.post_match
    end
  end

  def expand_slash_per_always
    # Expand / to "per" always.  Add spaces if needed.
    re = %r{(?<thingbefore>.)/(?<thingafter>.)}x
    while (result = re.match(@expanded_script))
      before = result[:thingbefore]
      after = result[:thingafter]
      @expanded_script = result.pre_match +
        before + (/[[:space:]]\Z/.match(before) ? '' : ' ') +
        'per' +
        (/\A[[:space:]]/.match(after) ? '' : ' ') + after +
        result.post_match
    end
  end

  def expand_slash_slash_always
    # Expand / to "slash" always.  Add spaces if needed.
    re = %r{(?<thingbefore>.)/(?<thingafter>.)}x
    while (result = re.match(@expanded_script))
      before = result[:thingbefore]
      after = result[:thingafter]
      @expanded_script = result.pre_match +
        before + (/[[:space:]]\Z/.match(before) ? '' : ' ') +
        'slash' +
        (/\A[[:space:]]/.match(after) ? '' : ' ') + after +
        result.post_match
    end
  end

  def expand_comma_space
    # Add a space after commas, if needed, and not inside a number.
    @expanded_script = @expanded_script
      .gsub(/([^[[:space:]]]),([^[[:digit:]][[:space:]]])/, "\\1, \\2")
      .gsub(/([^[[:space:]][[:digit:]]]),([^[[:space:]]])/, "\\1, \\2")
  end

  def expand_dash_to_to
    # Expand dashed numbers and dollars into numbers separated by the word "to".
    # So "12-45" or "12 - 45" expands to "12 to 45".  And $32 - $ 45.67 expands
    # to "$32 to $45.67.
    re = %r{
      (?<number1>[[:digit:]]+)
      [[:space:]]*
      [-‐‑‒–—⸺⸻﹘﹣－] # All known dash or minus characters.
      [[:space:]]*
      (?<number2>([[:digit:]]|(\$[[:space:]]*))([,.]?[[:digit:]])*)
      (?<thingafter>[^[[:digit:]]\-])
      }x
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match +
        result[:number1] + ' to ' + result[:number2] +
        result[:thingafter] + result.post_match
    end
  end

  def expand_dollars
    # Look for $ 123,456.78 type things.  The fractional .78 (two digits
    # means cents, otherwise it's a decimal fraction) and commas and space
    # after the dollar sign are optional.
    # $12.34 becomes "twelve dollars and thirty four cents"
    # $1.234 becomes "one point two three four dollars"
    re = /\$[[:space:]]*(?<number>[0-9][0-9,]*)(?<fraction>\.[0-9]+)?/
    while (result = re.match(@expanded_script))
      number = result[:number].delete(',')
      fraction = result[:fraction] # Remember it includes the period in front.
      int_number = number.to_i
      # Awkward code to avoid teensy limit of 3 nested blocks in Shopify rules.
      expanded_text = if (int_number == 0) && fraction
        '' # So that $0.23 comes out as just "twenty-three cents".
      else
        remove_and_dash(NumbersInWords.in_words(int_number)) + ' ' +
          'dollar'.pluralize(int_number)
      end
      if fraction && fraction.length != 3 # More or less than 2 digits at end.
        real_number = (number + fraction).to_f
        expanded_text = remove_and_dash(NumbersInWords.in_words(real_number)) +
          ' dollars'
      elsif fraction && fraction.length == 3
        int_fraction = fraction.delete_prefix('.').to_i
        expanded_text += ' and ' unless expanded_text.empty?
        expanded_text += NumbersInWords.in_words(int_fraction) + ' ' +
          'cent'.pluralize(int_fraction)
      end

      # Insert spaces if butting up against letters or something similar.
      unless /[[[:space:]][[:punct:]]]\Z/.match(result.pre_match)
        expanded_text = ' ' + expanded_text
      end
      unless /\A[[[:space:]][[:punct:]]]/.match(result.post_match)
        expanded_text += ' '
      end

      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_years
    # Expand 4 digit years, from 1000 to 2999, usually into two half numbers
    # (centuries and part of a century).  Need space before and space or
    # punctuation after.  So 1969 becomes nineteen sixty-nine.  1901 becomes
    # ninteen oh-one.  1900 becomes nineteen hundred.
    # 2000 becomes two thousand, 1000 becomes one thousand.
    re = /(?<space1>[[:space:]])(?<century>[12][0-9])(?<year>[0-9][0-9])(?<space2>[[:space:]]|[[:punct:]])/
    while (result = re.match(@expanded_script))
      century = result[:century].to_i
      year = result[:year].to_i
      if year <= 9 # 00 to 09, said as two thousand and five, 19 hundred and one.
        expanded_text = if century % 10 == 0
          NumbersInWords.in_words(century * 100) # Exact thousand year dates.
        else
          NumbersInWords.in_words(century) + ' hundred'
        end
        expanded_text += ' and ' + NumbersInWords.in_words(year) if year > 0
      else # Year 10 to 99 possible.
        expanded_text = NumbersInWords.in_words(century) + ' '
        expanded_text += NumbersInWords.in_words(year)
      end
      @expanded_script = result.pre_match + result[:space1] +
        expanded_text + result[:space2] + result.post_match
    end
  end

  def expand_leading_zeroes
    # Pure digit numbers (no commas or periods) starting with 0 get read
    # out as individual digits.  So 8:05 becomes 8:zero five
    # Zero becomes "oh" if :exp_leadingohs is on.
    re = %r{(?<spacebefore>[[[:space:]][[:punct:]]]?)
      (?<![0-9]|[0-9],|[0-9]\.) # Make sure there isn't a number before the number!
      (?<number>0[0-9]+) # Zero and at least one digit, single 0 not handled.
      (?<thingafter>[[[:space:]][[:punct:]]]?) # Test for spaceish afterwards.
    }x
    while (result = re.match(@expanded_script))
      expanded_text = if result[:spacebefore] && !result[:spacebefore].empty?
        result[:spacebefore]
      else # No space before, need to separate our new words from prior text.
        ' '
      end
      number_text = number_to_digits(result[:number])
      number_text = number_text.gsub(/zero/, 'oh') if @selected_expansions[:exp_leadingohs]
      expanded_text += number_text
      expanded_text += if result[:thingafter] && !result[:thingafter].empty?
        result[:thingafter]
      else # No space after, need to separate our new words from following text.
        ' '
      end
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_numbers
    # Positive numbers are expanded into words.  Note that the numbers can
    # be anywhere, even inside a word, so X15 or 9a become X fifteen or
    # nine a.  Though if it's followed by "st", "nd", "rd" or "th" then it
    # won't be expanded (avoids 22nd -> twenty twond).  Numbers can have commas and
    # decimal points, such as 123,456.78 which becomes: one hundred and
    # twenty-three thousand four hundred and fifty-six point seven eight.
    # The plus or minus sign in front will be left alone, and handled elsewhere.
    # Avoid ending in a comma.
    re = %r{
      (?<before>[[[:space:]][[:punct:]]])? # Is there a space before the number?
      (?<number>[0-9](,?[0-9])*(\.[0-9]+)?) # Number not ending in a comma.
      (?!st[[[:space:]][[:punct:]]]| # Not followed by st for 1st.
      nd[[[:space:]][[:punct:]]]| # Not followed by nd for 2nd.
      rd[[[:space:]][[:punct:]]]| # Not followed by rd for 3rd.
      th[[[:space:]][[:punct:]]]| # Not followed by th for 4th.
      [0-9]) # Not followed by a digit, should be part of the number.
    }x
    while (result = re.match(@expanded_script))
      expanded_text = if result[:before] && !result[:before].empty?
        result[:before]
      else
        ' ' # Need to insert a space before our new number text.
      end
      number = result[:number].delete(',')
      expanded_text += if number.include?('.')
        remove_and_dash(NumbersInWords.in_words(number.to_f))
      else
        remove_and_dash(NumbersInWords.in_words(number.to_i))
      end
      expanded_text += ' ' unless /\A[[[:space:]][[:punct:]]]/.match(result.post_match)
      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end
end
