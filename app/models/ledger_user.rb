# frozen_string_literal: true

class LedgerUser < LedgerBase
  alias_attribute :name, :string1
  alias_attribute :email, :string2
  alias_attribute :birthday, :date1
  alias_attribute :user_id, :number1

  def to_s
    if original_version.amended
      latest = latest_version
      (super + " (##{original_version_id}-#{latest.id} " \
        "{latest.name.truncate(25)})").truncate(255)
    else
      (super + " (#{name.truncate(25)})").truncate(255)
    end
  end

  def user
    User.find(user_id)
  end

  # Returns a collection of all the LedgerPosts the user should see in their
  # feed.  Currently it's just their own posts.
  def feed
    LedgerPost.where(creator_id: original_version_id).order(created_at: :desc)
  end
end
