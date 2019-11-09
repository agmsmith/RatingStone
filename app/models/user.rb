# frozen_string_literal: true

class User < ApplicationRecord
  before_save { email.downcase! } # Because database index is case sensitive.

  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
    format: { with: VALID_EMAIL_REGEX },
    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }

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
end
