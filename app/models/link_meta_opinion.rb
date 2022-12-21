# frozen_string_literal: true

class LinkMetaOpinion < LinkOpinion
  alias_attribute :opinion_about_link_id, :number1

  validates :opinion_about_link_id,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
