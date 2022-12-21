# frozen_string_literal: true

class LinkOpinion < LinkBase
  alias_attribute :author, :parent
  alias_attribute :author_id, :parent_id
  alias_attribute :opinion_about_object, :child
  alias_attribute :opinion_about_object_id, :child_id
  alias_attribute :reason_why, :string1

  alias_attribute :boost_author, :rating_points_boost_parent
  alias_attribute :boost_object, :rating_points_boost_child
  alias_attribute :direction_author, :rating_direction_parent
  alias_attribute :direction_object, :rating_direction_child

  validates :reason_why, length: { maximum: 255 }
end
