# frozen_string_literal: true

class User < ApplicationRecord
  before_save :downcase_email
  before_create :create_activation_digest

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

  # Activates an account.  And adds a bonus link if needed.
  def activate
    return if activated

    update_columns(activated: true, activated_at: Time.zone.now)

    # Add a bonus to the corresponding LedgerUser for e-mail verification done.
    bonus_post = LedgerPost.where(subject: "Bonus for Activation")
      .order(created_at: :asc).first # Get oldest post with that subject.
    return unless bonus_post # Odd, no post for describing the activation bonus.

    luser = ledger_user # Creates LedgerUser if needed.
    LinkBonusUnique.create!(creator_id: 0, bonus_user: luser,
      bonus_explanation: bonus_post, bonus_points: 10, rating_points_spent: 1.0,
      rating_points_boost_parent: 0.25, rating_points_boost_child: 0.75,
      approved_parent: true, approved_child: true,
      reason: "Bonus for activating #{luser} via e-mail verification.")
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
  # if none then creates one and sets up a new user.
  def ledger_user
    lu = LedgerUser.find_by(id: ledger_user_id) if ledger_user_id
    if lu.nil?
      lu = LedgerUser.create!(creator_id: 0, name: name, email: email,
        rating_points_spent_creating: # Initial points to cover home group.
          LedgerAwardCeremony::DEFAULT_SPEND_FOR_OBJECT * 2 +
          LedgerAwardCeremony::DEFAULT_SPEND_FOR_LINK,
        current_ceremony: LedgerAwardCeremony.last_ceremony)
      self.ledger_user_id = lu.id
      save!
      lu.set_up_new_user # Home group etc.
    else
      lu = lu.latest_version
    end
    lu
  end

  # Make sure the corresponding LedgerUser has current e-mail and name.  Throws
  # an exception if there aren't enough points available to create the new
  # version of the LedgerUser record.
  def update_ledger_user_email_name
    luser = ledger_user # Gets latest version of the data.
    return if (luser.name == name) && (luser.email == email)

    new_luser = luser.append_version
    new_luser.name = name
    new_luser.email = email
    new_luser.save!
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
end
