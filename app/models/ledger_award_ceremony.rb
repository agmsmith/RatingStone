# frozen_string_literal: true

class LedgerAwardCeremony < LedgerBase
  alias_attribute :ceremony_number, :number1
  alias_attribute :completed_at, :date1

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    "Award Ceremony ##{ceremony_number} completed at #{completed_at}"
  end

  ##
  # Class function to start an award ceremony.  Usually called by a weekly cron
  # script on the web server, but can also be triggered manually.
  def self.start_ceremony
    ceremony = nil
    # Wrap this in a transaction so nothing changes while we update everything.
    # Hopefully the database won't explode with the large transaction size!
    transaction do
      ceremony = self.new(creator_id: 0)
      max_ceremony = self.maximum(:ceremony_number)
      ceremony.ceremony_number = if max_ceremony
        max_ceremony + 1
      else # No ceremonies done yet, first one starts at 1.
        1
      end
      ceremony.save
      sleep(2)
      ceremony.completed_at = Time.zone.now
      ceremony.save
    end
    ceremony
  end
end
