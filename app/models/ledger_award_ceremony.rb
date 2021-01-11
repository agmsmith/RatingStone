# frozen_string_literal: true

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
  # Class function to find the number of the last ceremony done.
  def self.last_ceremony
    return @highest_ceremony if @highest_ceremony
    @highest_ceremony = maximum(:ceremony_number)
    @highest_ceremony = 0 unless @highest_ceremony # If no ceremonies done yet.
    @highest_ceremony
  end

  ##
  # Class function to start an award ceremony.  Usually called by a weekly cron
  # script on the web server, but can also be triggered manually.
  def self.start_ceremony
    ceremony = nil
    # Wrap this in a transaction so nothing changes while we update everything.
    # Hopefully the database won't explode with the large transaction size!
    transaction do
      ceremony = new(creator_id: 0, ceremony_number: last_ceremony + 1)
      ceremony.save!
      @highest_ceremony = ceremony.ceremony_number
      # Do the ceremony processing...
      sleep(2) unless Rails.env.test?
      ceremony.completed_at = Time.zone.now
      ceremony.save!
    end
    ceremony
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
