# frozen_string_literal: true

class LedgerUser < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :email, :string2
  alias_attribute :birthday, :date1

  after_create :update_created_by_self

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
        name: latest_name,
        description: "Personal Posts by #{latest_name}")
      LinkHomeGroup.create!(creator_id: original_version_id,
        parent_id: original_version_id, child: lfgroup)
    end
  end

  ##
  # Returns a collection of all the LedgerPosts the user should see in their
  # feed.  Currently it's just their own posts.
  def feed
    LedgerPost.where(creator_id: original_version_id).order(created_at: :desc)
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
  # For auto-approval of link parent or child where the parent or child is a
  # user, we need to make the user the creator or owner of themselves.  But
  # we don't know our own record ID until after the record has been saved.
  def update_created_by_self
    update_attribute(:creator_id, original_version_id)
  end
end
