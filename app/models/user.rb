# frozen_string_literal: true

class User < ApplicationRecord
  before_save :downcase_email
  before_create :create_activation_digest
  after_save :update_ledger_user

  has_many :microposts, dependent: :destroy

  # Relationship things...
  has_many :active_relationships, class_name: :Relationship,
    foreign_key: :follower_id, dependent: :destroy
  has_many :passive_relationships, class_name: :Relationship,
    foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  attr_accessor :activation_token, :remember_token, :reset_token

  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
    format: { with: VALID_EMAIL_REGEX },
    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Use password_digest field, defines password & password_confirmation attr.
  has_secure_password

  # Returns the hash digest of the given string, useful for making test users.
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
      BCrypt::Engine::MIN_COST
    else
      BCrypt::Engine.cost
    end
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token string, 22 safe for URL use characters.
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remember logins using a persistent cookie value, we just store a digest.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches a particular kind of
  # digest (remember, activation).
  def authenticated?(digest_kind, token)
    digest = send("#{digest_kind}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.  Saved cookie will no longer log them in.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token),
      reset_sent_at: Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Returns the latest version LedgerUser record corresponding to this user,
  # if none then creates one, preferably reusing the id number of the User
  # (mostly important for low numbered sysop accounts where the id value
  # is used to determine their priviledge).
  def ledger_user
    lu = LedgerUser.find_by(id: ledger_user_id) if ledger_user_id
    if lu.nil?
      lu = if LedgerUser.exists?(id: id)
        LedgerUser.create!(creator_id: 0, name: name,
          email: email, user_id: id)
      else # Can force a specific ID number for new record.
        LedgerUser.create!(id: id, creator_id: 0, name: name,
          email: email, user_id: id)
      end
      self.ledger_user_id = lu.id # Need self.attr here to make it work.
      save!
    else
      lu = lu.latest_version
    end
    if (ledger_user_id != lu.original_version_id) || (lu.user_id != id)
      raise "Database problem - reference not bidirectional between " \
        "User ##{id} and #{lu}.  Database corrupt?"
    end
    lu
  end

  # Returns a collection of all the Microposts the user should see in their
  # feed.  Currently it's posts from followed users and their own posts.
  def feed
    Micropost.where(user: id).or(Micropost.where(
      user: Relationship.where(follower: id).select(:followed_id)
    ))
  end

  # Follows a user.
  def follow(other_user)
    following << other_user
  end

  # Unfollows a user.
  def unfollow(other_user)
    following.delete(other_user)
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    following.include?(other_user)
  end

  private

  # Change email to all lower-case, because database index is case sensitive.
  def downcase_email
    email.downcase!
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

  # If there is a corresponding LedgerUser, update its name and email.
  def update_ledger_user
    return if ledger_user_id.nil?
    luser = ledger_user # Gets latest version of the data.
    return if (luser.name == name) && (luser.email == email)
    new_luser = luser.append_version
    new_luser.name = name
    new_luser.email = email
    new_luser.save!
  end
end
