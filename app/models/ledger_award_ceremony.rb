# frozen_string_literal: true

# TODO: Method for finding a ceremony number when given a date.
# TODO: Method for figuring out points from adding bonuses over a given number
# of ceremonies, can cache it as a lookup table from 0 to latest ceremony
# number.  Multiply weekly award bonus points by the method value to get
# current day points including faded accumulation.

class LedgerAwardCeremony < LedgerBase
  alias_attribute :ceremony_number, :number1
  alias_attribute :completed_at, :date1

  FADE = 0.97
  # How much to fade ratings points by in an awards ceremony.  The 0.97 factor
  # Cuts things down to about 1% of their original size after 3 years of weekly
  # fading.

  @highest_ceremony = nil
  # Class variable storing the highest ceremony number, or nil if not known
  # yet.  Computed on demand and cached here.  Will be incremented when a new
  # award ceremony starts processing.

  ##
  # Class function to find the number of the last ceremony done.  Zero if no
  # ceremonies done yet, else number of highest ceremony.  They're assumed to
  # be increasing sequential numbers, else fading will be excessive.
  def self.last_ceremony
    return @highest_ceremony if @highest_ceremony
    @highest_ceremony = maximum(:ceremony_number)
    @highest_ceremony = 0 unless @highest_ceremony # If no ceremonies done yet.
    @highest_ceremony
  end

  ##
  # Class function to start an award ceremony.  Usually called by a weekly cron
  # script on the web server, but can also be triggered manually.  Returns the
  # new ceremony record.
  def self.start_ceremony
    result = nil
    # Wrap this in a transaction so the ceremony gets cancelled if something
    # goes wrong.
    transaction do
      ceremony = new(creator_id: 0, ceremony_number: last_ceremony + 1)
      ceremony.save!
      @highest_ceremony = nil
      # Do the ceremony processing...
      sleep(2) unless Rails.env.test?
      ceremony.completed_at = Time.zone.now
      ceremony.save!
      result = ceremony
      logger.info("  Awards ceremony ##{ceremony.ceremony_number} completed " \
        "successfully after #{ceremony.completed_at - ceremony.created_at} " \
        "seconds.")
    end
    result
  end

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    "Award Ceremony ##{ceremony_number} completed at #{completed_at}, " \
    "took #{(completed_at - created_at).round(1)} seconds"
  end
end
