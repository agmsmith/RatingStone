# frozen_string_literal: true

class LedgerUser < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :email, :string2

  after_create :user_after_create

  def context_s
    latest_version.name.truncate(25)
  end

  ##
  # Returns the User record for this LedgerUser, or nil if there is none
  # (happens if the User gets deleted).  Previously we used to automatically
  # create a User record, but now use create_user for that.
  def user
    User.find_by(ledger_user_id: original_version_id)
  end

  ##
  # Create a User record for an existing LedgerUser.  Usually the User comes
  # first, but for testing we sometimes make the LedgerUser first.
  def create_user
    user_record = user
    return user_record if user_record # Already exists.

    # Need to make a new User record, an unusual procedure.  Set it up with a
    # random password so a password reset to the user's email is needed for
    # actual access.
    logger.warn("Creating a User for #{self}, an unusual reversed procedure.")
    pw = SecureRandom.hex
    user_record = User.create!(ledger_user_id: original_version_id,
      name: name, email: email, password: pw, password_confirmation: pw,
      admin: false, activated: false)
    user_record.activate
    user_record
  end

  ##
  # Do some extra setup for new users.  Make their personal group.  Safe to
  # call multiple times, just does nothing if already set up.
  def set_up_new_user
    # Make a home group for the new user.
    if home_group.nil?
      latest_name = latest_version.name
      lfgroup = LedgerFullGroup.create!(creator_id: original_version_id,
        name: latest_name, description: "Personal Posts by #{latest_name}",
        rating_points_spent_creating: 0.0, rating_points_boost_self: 0.0)
      # Root gives points to user by creating this link, avoiding the problem
      # of the LedgerUser creator change to be the user rather than Root,
      # which would mess up the accounting badly.
      LinkHomeGroup.create!(creator_id: 0,
        parent_id: original_version_id, child: lfgroup,
        approved_parent: true, approved_child: true,
        string1: "Special initial link between #{latest_name.truncate(80)} " \
          "and their home page, paid for by the system.",
        rating_points_spent: DEFAULT_SPEND_FOR_OBJECT * 2,
        rating_points_boost_parent: DEFAULT_SPEND_FOR_OBJECT,
        rating_points_boost_child: DEFAULT_SPEND_FOR_OBJECT)
    end
  end

  ##
  # Returns a collection of all the LedgerPosts the user should see in their
  # feed.  Currently it's just their own posts.
  def feed
    LedgerPost.where(creator_id: original_version_id,
      is_latest_version: true).order(created_at: :desc)
  end

  ##
  # Return the home group (a LedgerFullGroup) for the user, or nil if none.
  # It's the special group created for them to post about themselves.
  # Identified by the most recent active LinkHomeGroup record.
  def home_group
    latest_home_link = LinkHomeGroup.where(parent_id: original_version_id,
      deleted: false, approved_parent: true, approved_child: true)
      .order(created_at: :desc).first
    return nil if latest_home_link.nil?

    home_page = latest_home_link.child.latest_version
    raise RatingStoneErrors,
      "Home page latest version from #{latest_home_link} " \
        "is not a LedgerFullGroup." unless home_page.is_a?(LedgerFullGroup)
    home_page
  end

  private

  ##
  # Adds the effect of other kinds of bonus points on the current points, since
  # the given ceremony number.  Called by update_current_points, with a lock on
  # this object already in effect, will save it too later on.
  def update_current_bonus_points_since(old_ceremony, last_ceremony)
    weekly_allowance = 0.0
    # Note that LinkBonus used in a query implies searches for LinkBonusUnique
    # too, but only if the single table inhertance system knows that the
    # LinkBonusUnique exists, thus the dummy reference.  The .class afterwards
    # is to pacify Rubocop.
    LinkBonusUnique.class
    # Iterate through the bonuses from negative to positive, so that we can cut
    # off excess positive bonuses which exceed the weekly total maximum.
    LinkBonus.where(approved_parent: true, approved_child: true,
      deleted: false, bonus_user_id: original_version_id)
      .order(bonus_points: :asc).each do |a_bonus|
      start_ceremony = if old_ceremony < a_bonus.original_ceremony
        a_bonus.original_ceremony
      else
        old_ceremony
      end
      expiry_ceremony = a_bonus.expiry_ceremony

      generations_fade = if last_ceremony <= expiry_ceremony
        0 # Bonus hasn't ended yet, no extra fading needed.
      else # Bonus ended in the past, fade the accumulated bonus a bit.
        last_ceremony - expiry_ceremony
      end

      generations_bonus = if expiry_ceremony > last_ceremony
        last_ceremony - start_ceremony
      else # Bonus has ended earlier in time.
        expiry_ceremony - start_ceremony
      end

      # Note that zero or negative generations means no bonus.  Usually happens
      # in first week when the bonus doesn't take effect yet, or for a far
      # future bonus.
      next if generations_bonus <= 0

      # Chop down the bonus if it makes the weekly total go over the maximum,
      # though root user and sysops (record id 0 through 9) don't have a limit.
      bonus_points = a_bonus.bonus_points
      if id >= 10 && weekly_allowance + bonus_points >
          LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY
        bonus_points =
          LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY - weekly_allowance
      end

      self.current_meh_points += bonus_points *
        LedgerAwardCeremony.accumulated_bonus(generations_bonus) *
        LedgerAwardCeremony::FADE**generations_fade
      weekly_allowance += bonus_points
      break if weekly_allowance >= LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY
    end

    weekly_allowance = 0.0 if weekly_allowance < 0.0
    user = User.find_by(ledger_user_id: original_version_id)
    user&.with_lock do
      user.update_columns(weeks_allowance: weekly_allowance,
        weeks_spending: 0.0)
    end
  end

  ##
  # For auto-approval of link parent or child where the parent or child is a
  # user, we need to make the user the creator or owner of themselves.  But
  # we don't know our own record ID until after the record has been created.
  # But only do that for new LedgerUser records, amended ones keep the current
  # creator.
  def user_after_create
    update_columns(creator_id: id) if original_version?
  end
end
