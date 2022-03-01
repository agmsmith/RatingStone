# frozen_string_literal: true

# TODO: Method for finding a ceremony number when given a date.

class LedgerAwardCeremony < LedgerBase
  alias_attribute :ceremony_number, :number1
  alias_attribute :completed_at, :date1
  alias_attribute :comment, :string1

  DAYS_PER_CEREMONY = 7
  # Number of days between ceremonies.  Usually a week, but that's up to the
  # system operator (usually a cron job).  Used in expiry estimates.

  FADE = 0.97
  FADE_LOG = Math.log(FADE)
  # How much to fade ratings points by in an awards ceremony.  The 0.97 factor
  # Cuts things down to about 1% of their original size after 3 years of weekly
  # fading.

  FADED_TO_NOTHING = 0.01
  # When you have this many points or less, a LinkBase is considered to be
  # faded away enough to be expired and worth garbage collecting.  LedgerBase
  # objects are also considered expired when they have no links to them and
  # the largest of their current points is this big.

  FADED_BONUS_TABLE_SIZE = 500
  FADED_BONUS_CONVERGED = 1.0 / (1.0 - FADE)
  @accumulated_faded_bonus_table = nil
  # To avoid recalculating the accumulated bonus points (we don't have a
  # simple equation for it), store the values here in an array of size
  # FADED_BONUS_TABLE_SIZE.  Though after a few hundred iterations (for 0.97)
  # it converges on 1/(1-FADE).  Nil if not initialised yet.

  @highest_ceremony = nil
  # Class variable storing the highest ceremony number, or nil if not known
  # yet.  Computed on demand and cached here.  Will be incremented when a new
  # award ceremony starts processing (will be in single threaded mode so other
  # web server processes with a similar but different global variable won't
  # exist).

  ##
  # Class function to calculate the cummulative accumulation of bonus points
  # added at every ceremony to a user's points.  Give it the number of elapsed
  # ceremonies and it will figure out the accumulated faded sum of 1 point
  # weekly.  Multiply that by the number of weekly bonus points to get the
  # long term effect on total points of a user.  After a number of iterations
  # it converges on 1/(1-FADE).
  def self.accumulated_bonus(elapsed_ceremonies)
    return 0.0 if elapsed_ceremonies < 1
    return FADED_BONUS_CONVERGED if elapsed_ceremonies >= FADED_BONUS_TABLE_SIZE

    if @accumulated_faded_bonus_table.nil?
      accumulated = 0.0
      @accumulated_faded_bonus_table = Array.new(FADED_BONUS_TABLE_SIZE) do
        prev = accumulated # Previous value used so array[0] starts at zero.
        accumulated = accumulated * FADE + 1.0
        prev
      end
    end
    @accumulated_faded_bonus_table[elapsed_ceremonies]
  end

  ##
  # Class function to find the number of the last ceremony done.  Zero if no
  # ceremonies done yet, else number of highest ceremony.  They're assumed to
  # be increasing sequential numbers, else fading will be excessive.
  def self.last_ceremony
    return @highest_ceremony if @highest_ceremony
    @highest_ceremony = maximum(:ceremony_number) # Find largest in database.
    @highest_ceremony = 0 unless @highest_ceremony # If no ceremonies done yet.
    @highest_ceremony
  end

  ##
  # Class function to clear the last ceremony cache.  Only used when testing
  # since the test framework sometimes leaves the @highest_ceremony unchanged.
  # Other than that, you don't need to call this since the ceremony is
  # performed in single tasking mode when the web server isn't running.
  def self.clear_ceremony_cache
    @highest_ceremony = nil
  end

  ##
  # Class function to start an award ceremony.  Usually called by a weekly cron
  # script on the web server, but can also be triggered manually.  Returns the
  # new ceremony record.  You can provide a descriptive comment if you wish.
  def self.start_ceremony(comment_string = "Routine ceremony.")
    result = nil
    # Wrap this in a transaction so the ceremony gets cancelled if something
    # goes wrong, also leave @highest_ceremony valid in that case.
    transaction do
      ceremony = new(creator_id: 0, ceremony_number: last_ceremony + 1,
        comment: comment_string)
      ceremony.save!
      @highest_ceremony = nil # Current ceremony number changed, force updates.

      # Do the ceremony processing.  Currently the actual fading work is done
      # incrementally on request (see #update_current_points).  May later do
      # garbage collection here of obsolete forgotten links and objects.
      sleep(2) unless Rails.env.test?
      ceremony.completed_at = Time.zone.now
      ceremony.save!

      result = ceremony
      logger.info("  Awards ceremony ##{ceremony.ceremony_number} completed " \
        "successfully after #{ceremony.completed_at - ceremony.created_at} " \
        "seconds.")
    end
    clear_ceremony_cache if result.nil?
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
