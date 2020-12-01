# frozen_string_literal: true

require 'numbers_in_words'

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
      @vo_script = @vo_script.strip # Form textarea adds a blank line at front.
      @selected_expansions[:exp_dollars] = true if params[:exp_dollars]
      @selected_expansions[:exp_dash_numbers] = true if params[:exp_dash_numbers]
      @selected_expansions[:exp_years] = true if params[:exp_years]
      @selected_expansions[:exp_numbers] = true if params[:exp_numbers]
      @selected_expansions[:exp_hyphens] = true if params[:exp_hyphens]
    else
      @vo_script = "Replace this text with your script..."
      @selected_expansions[:exp_dollars] = true
      @selected_expansions[:exp_dash_numbers] = false
      @selected_expansions[:exp_years] = true
      @selected_expansions[:exp_numbers] = true
      @selected_expansions[:exp_hyphens] = true
    end

    @expanded_script = ' ' + @vo_script + ' ' # Spaces to avoid edge conditions.

    # Expand dollar amounts.

    if @selected_expansions[:exp_dollars]
      # Look for $ 123,456.78 type things.  The .78 (two digits required) and
      # commas and space are optional.
      re = /\$\s*(?<number>[0-9][0-9,]*)(?<fraction>\.[0-9][0-9])?/
      while (result = re.match(@expanded_script)) do
        number = result[:number].delete(',').to_i
        if number == 0 && result[:fraction]
          expanded_text = '' # So that $0.23 comes out as "twenty-three cents".
        else
          expanded_text = NumbersInWords.in_words(number) + ' ' +
            'dollar'.pluralize(number)
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

    # Expand dashed numbers into numbers separated by the word "to".
    # So "12-45" or "12 - 45" expands to "12 to 45".

    if @selected_expansions[:exp_dash_numbers]
      re = /(?<number1>[0-9]+)[[:space:]]*-[[:space:]]*(?<number2>[0-9]+)/
      while (result = re.match(@expanded_script)) do
        @expanded_script = result.pre_match + result[:number1] + ' to ' +
          result[:number2] + result.post_match
      end
    end

    # Expand 4 digit years, from 1000 to 2999 into two half numbers.  So 1969
    # becomes nineteen sixty-nine.  Need spaces before and space or punctuation
    # after.

    if @selected_expansions[:exp_years]
      re = /(?<space1>[[:space:]])(?<century>[12][0-9])(?<year>[0-9][0-9])(?<space2>[[:space:]]|[[:punct:]])/
      while (result = re.match(@expanded_script)) do
        century = result[:century].to_i
        year = result[:year].to_i
        if year == 0
          if century % 10 == 0
            expanded_text = NumbersInWords.in_words(century * 100)
          else
            expanded_text = NumbersInWords.in_words(century) + ' hundred'
          end
        else
          expanded_text = NumbersInWords.in_words(century) + ' '
          expanded_text += 'oh-' if year < 10
          expanded_text += NumbersInWords.in_words(year)
        end
        @expanded_script = result.pre_match + result[:space1] +
          expanded_text + result[:space2] + result.post_match
      end
    end

    # Expand positive numbers, which can be decimal fractions.  Don't expand if
    # followed by letters, like "22nd".  Punctuation or spaces are okay.

    if @selected_expansions[:exp_numbers]
      # Look for 123,456.78 type things.  Avoid ending in a comma.
      re = /(?<number>[0-9](,?[0-9])*(\.[0-9]+)?)(?<after>[[:space:]]|[[:punct:]])/
      while (result = re.match(@expanded_script)) do
        number = result[:number].delete(',')
        if number.include?('.')
          expanded_text = NumbersInWords.in_words(number.to_f)
        else
          expanded_text = NumbersInWords.in_words(number.to_i)
        end
        @expanded_script = result.pre_match + expanded_text +
          result[:after] + result.post_match
      end
    end

    # Replace hyphens with spaces.  Need to have letters on both sides of the
    # hyphen to avoid clobbering minus signs and other hyphen uses.

    if @selected_expansions[:exp_hyphens]
      re = /(?<letter1>[[:alpha:]])-(?<letter2>[[:alpha:]])/
      while (result = re.match(@expanded_script)) do
        @expanded_script = result.pre_match + result[:letter1] +
          ' ' + result[:letter2] + result.post_match
      end
    end

    # Calculate some statistics on the words.
    @original_word_count = @vo_script.strip.split(/\s+/).length
    words = @expanded_script.strip.downcase.split(/\s+/).sort
    @expanded_word_count = words.length
    @word_list = Hash.new(0)
    words.each do |word|
      @word_list[word] += 1
    end
    render
  end
end
