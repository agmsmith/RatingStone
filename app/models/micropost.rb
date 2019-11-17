# frozen_string_literal: true

class Micropost < ApplicationRecord
  belongs_to :user
  default_scope -> { order(created_at: :desc) } # SQL: order('created_at DESC')
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end
