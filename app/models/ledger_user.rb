# frozen_string_literal: true

class LedgerUser < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :email, :string2

  after_create :user_after_create

  def context_s
    latest_version.name.truncate(25)
  end

  def user
    user_record = User.find_by(ledger_user_id: original_version_id)
    return user_record if user_record
    # Need to make a new User record, an unusual procedure.  Set it up so
    # a password reset to the user's email is needed for access.
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
      LinkHomeGroup.create!(creator_id: 0, # Root will pay for it.
        parent_id: original_version_id, child: lfgroup,
        approved_parent: true, approved_child: true,
        rating_points_spent: 1.0,
        rating_points_boost_parent: 0.0,
        rating_points_boost_child: 1.0)
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
  # Return the home group for the user, or nil if none.  It's the special group
  # created for them to post about themselves.  Identified by the most recent
  # LinkHomeGroup record.
  def home_group
    latest_home = LinkHomeGroup.where(parent_id: original_version_id,
      deleted: false, approved_parent: true, approved_child: true)
      .order(created_at: :desc).first
    return nil if latest_home.nil?
    home_page = latest_home.child.latest_version
    raise RatingStoneErrors, "Home page latest version from #{latest_home} " \
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
      deleted: false, bonus_user_id: original_version_id).
      order(bonus_points: :asc).each do |a_bonus|
      start_ceremony = if old_ceremony < a_bonus.original_ceremony
        a_bonus.original_ceremony
      else
        old_ceremony
      end
      generations = last_ceremony - start_ceremony

      # Note that zero or negative generations means no bonus, so you don't get
      # the bonus until the next ceremony after the bonus is created.
      next if generations <= 0

      # Chop down the bonus if it makes the weekly total go over the maximum.
      bonus_points = a_bonus.bonus_points
      if weekly_allowance + bonus_points >
          LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY
        bonus_points =
          LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY - weekly_allowance
      end

      self.current_meh_points += bonus_points *
        LedgerAwardCeremony.accumulated_bonus(generations)
      weekly_allowance += bonus_points
      break if weekly_allowance >= LedgerAwardCeremony::MAXIMUM_BONUS_PER_CEREMONY
    end

    user = User.find_by(ledger_user_id: original_version_id)
    user&.with_lock do
      weekly_allowance = 0.0 if weekly_allowance < 0.0
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
