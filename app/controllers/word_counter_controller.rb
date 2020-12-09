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
  def update
    @vo_script = params[:vo_script]
    @selected_expansions = Hash.new(false)
    if @vo_script
      # Use an empty script if Clear button pressed, otherwise remove the blank
      # line that the Form textarea adds at front, depending on the browser.
      @vo_script = params[:commit] == 'Clear' ? '' : @vo_script.strip
      @selected_expansions[:exp_dollars] = true if params[:exp_dollars]
      @selected_expansions[:exp_urls] = true if params[:exp_urls]
      @selected_expansions[:exp_na_telephone] = true if params[:exp_na_telephone]
      @selected_expansions[:exp_say_area_code] = true if params[:exp_say_area_code]
      @selected_expansions[:exp_say_telephone_number] = true if params[:exp_say_telephone_number]
      @selected_expansions[:exp_dash_numbers] = true if params[:exp_dash_numbers]
      @selected_expansions[:exp_years] = true if params[:exp_years]
      @selected_expansions[:exp_numbers] = true if params[:exp_numbers]
      @selected_expansions[:exp_hyphens] = true if params[:exp_hyphens]
    else # First time run, use some demo text and default settings.
      @vo_script = "Replace this text with your script.  For example, save " \
        "$123.45 on word-costs in 2020, compared to 1990's fees; that's a " \
        "50% savings!  Only 1,234.56 seconds remain before this offer " \
        "expires!  Give us a call at 1-800-555-1234, but before 2020.12.07 " \
        "6:01 a.m. (that's December 7th, 2020, 06:01) or...  Alternatively, " \
        "visit https://ratingstone.agmsmith.ca/server01/about for more " \
        "information or search on www.google.com for hints & tips (use " \
        "#RealWordCount) or write to agmsrepsys@gmail.com.  On Facebook " \
        "we're @RealCount."
      @selected_expansions[:exp_dollars] = true
      @selected_expansions[:exp_urls] = true
      @selected_expansions[:exp_na_telephone] = true
      @selected_expansions[:exp_say_area_code] = false
      @selected_expansions[:exp_say_telephone_number] = false
      @selected_expansions[:exp_dash_numbers] = true
      @selected_expansions[:exp_years] = true
      @selected_expansions[:exp_numbers] = true
      @selected_expansions[:exp_hyphens] = true
    end

    @expanded_script = ' ' + @vo_script + ' ' # Spaces to avoid edge conditions.

    expand_dollars if @selected_expansions[:exp_dollars]
    expand_urls if @selected_expansions[:exp_urls]
    expand_na_telephone if @selected_expansions[:exp_na_telephone]
    expand_dash_numbers if @selected_expansions[:exp_dash_numbers]
    expand_years if @selected_expansions[:exp_years]
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

  # Various methods for expanding things.  Input and output is @expanded_script.

  def expand_dollars
    # Look for $ 123,456.78 type things.  The fractional .78 (two digits
    # required) and commas and space after the dollar sign are optional.
    # $12.34 becomes "twelve dollars and thirty four cents"
    re = /\$[[:space:]]*(?<number>[0-9][0-9,]*)(?<fraction>\.[0-9]+)?/
    while (result = re.match(@expanded_script))
      number = result[:number].delete(',').to_i
      expanded_text = if (number == 0) && result[:fraction]
        '' # So that $0.23 comes out as just "twenty-three cents".
      else
        NumbersInWords.in_words(number) + ' ' + 'dollar'.pluralize(number)
      end
      if result[:fraction]
        fraction = result[:fraction].delete_prefix('.').to_i
        expanded_text += " and " unless expanded_text.empty?
        expanded_text += NumbersInWords.in_words(fraction) + ' ' +
          'cent'.pluralize(fraction)
      end
      @expanded_script = result.pre_match + expanded_text + result.post_match
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
    # If @selected_expansions[:exp_say_area_code] is true then the words
    # "area code" are inserted before the area code if there is one.  To have
    # it say "telephone number" before the last seven digits part, set
    # @selected_expansions[:exp_say_telephone_number] to true.

    # Leading long distance country code: ((?<leadingone>1)(-|[[:space:]]+))?
    # Area code: (\(?(?<areacode>[2-9][0-9][0-9])(-|(\)?[[:space:]]+)))
    # Number: (?<exchange>[2-9][0-9][0-9])(-|[[:space:]])(?<number>[0-9][0-9][0-9][0-9])
    # If there's a leading 1, need an area code: (leadingone? areacode)? number
    re = %r{(?<spacebefore>[[:space:]])
      (((?<leadingone>1)(-|[[:space:]]+))?
      (\(?(?<areacode>[2-9][0-9][0-9])(-|(\)?[[:space:]]+))))?
      (?<exchange>[2-9][0-9][0-9])(-|[[:space:]])
      (?<number>[0-9][0-9][0-9][0-9])
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
      expanded_text += result[:spaceafter]

      @expanded_script = result.pre_match + expanded_text + result.post_match
    end
  end

  def expand_dash_numbers
    # Expand dashed numbers into numbers separated by the word "to".
    # So "12-45" or "12 - 45" expands to "12 to 45".
    re = %r{(?<spacebefore>[[:space:]])
      (?<number1>[0-9]+)[[:space:]]*
      -
      [[:space:]]*(?<number2>[0-9]+)
      (?<spaceafter>[[[:space:]][[:punct:]]])
      }x
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match + result[:spacebefore] +
        result[:number1] + ' to ' + result[:number2] +
        result[:spaceafter] + result.post_match
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
      if year == 0
        expanded_text = if century % 10 == 0
          NumbersInWords.in_words(century * 100) # Exact thousand year dates.
        else
          NumbersInWords.in_words(century) + ' hundred'
        end
      else # Not the year 00 start of a century, 01 to 99 possible.
        expanded_text = NumbersInWords.in_words(century) + ' '
        expanded_text += 'oh-' if year < 10
        expanded_text += NumbersInWords.in_words(year)
      end
      @expanded_script = result.pre_match + result[:space1] +
        expanded_text + result[:space2] + result.post_match
    end
  end

  def expand_numbers
    # Expand positive numbers, which can be decimal fractions.  The plus or
    # minus sign in front will be left alone, and read normally, maybe.
    # Don't expand if # followed by letters, like "22nd", would get the awkward
    # "twenty twond".  Punctuation or spaces are expected after the number.
    # Look for 123,456.789 type things.  Avoid ending in a comma.
    re = /(?<number>[0-9](,?[0-9])*(\.[0-9]+)?)(?<after>[[:space:]]|[[:punct:]])/
    while (result = re.match(@expanded_script))
      number = result[:number].delete(',')
      expanded_text = if number.include?('.')
        NumbersInWords.in_words(number.to_f)
      else
        NumbersInWords.in_words(number.to_i)
      end
      @expanded_script = result.pre_match + expanded_text + result[:after] +
        result.post_match
    end
  end

  def expand_urls
    # Extract a whole URL from the text then apply several processing steps to
    # it then put the expanded version back.  Needs to work for
    # https://www.example.com/stuff/more/ and for mit.edu but not 2.3 or p.m.
    re = %r{
      (?<spacebefore>[[:space:]]) # Space before the URL required.
      (?<http>[[:alpha:]]+://)? # Optional HTTP:// or HTTPS:// or FTP:// prefix.
      (?<middle>[[:alpha:]] # No initial digit allowed, start with a letter.
        [[:alnum:]]+ # Finish the first word, 2 or more letters.
        ([./@:][[:alnum:]][[:alnum:]]+)+ # Need more separators and more words.
        /?) # Optional trailing slash.
      (?<spaceafter>[[[:space:]][[:punct:]]]) # Ends with space or punctuation.
    }xi # x for ignore spaces in definition, i for case insensitive.
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match + result[:spacebefore] +
        (result[:http] ? result[:http].gsub(%r{://}, " colon slash slash ") : '') +
        result[:middle]
          .gsub(/\./, ' dot ').gsub(%r{/}, ' slash ')
          .gsub(/@/, ' at ').gsub(/:/, ' colon ').strip +
        result[:spaceafter] + result.post_match
    end
  end

  def expand_hyphens
    # Replace hyphens with spaces.  Need to have letters on both sides of the
    # hyphen to avoid clobbering minus signs and other hyphen uses.
    re = /(?<letter1>[[:alpha:]])-(?<letter2>[[:alpha:]])/
    while (result = re.match(@expanded_script))
      @expanded_script = result.pre_match + result[:letter1] + ' ' +
        result[:letter2] + result.post_match
    end
  end
end