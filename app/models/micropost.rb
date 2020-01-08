# frozen_string_literal: true

class Micropost < ApplicationRecord
  belongs_to :user
  has_many_attached :images
  default_scope -> { order(created_at: :desc) } # SQL: order('created_at DESC')
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
  validates :images,
    content_type: {
      in: %w[image/jpeg image/gif image/png],
      message: "must be a picture format we can handle (JPEG, PNG, GIF)",
    },
    size: {
      less_than: 5.megabytes,
      message: "should be less than 5 megabytes",
    }

  # Returns a resized image for display.
  def displayable_image(image)
    image.variant(resize_to_limit: [500, 500])
  end
end
