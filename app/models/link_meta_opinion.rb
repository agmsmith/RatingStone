# frozen_string_literal: true

require_relative "link_opinion.rb"

class LinkMetaOpinion < LinkOpinion
  alias_attribute :opinion_about_link_id, :number1

  validates :opinion_about_link_id,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  ##
  # Just append the link reference to the stock description string.
  def to_s
    description = super.sub(/\)?$/, ", metalink ") # Remove optional trailing ")".
    link = LinkBase.find_by(id: opinion_about_link_id)
    description += if link
      link.base_s
    else
      "##{opinion_about_link_id}"
    end
    description + ")"
  end

  ##
  # Everybody involved can view an opinion.
  def allowed_to_view?(luser)
    return true if super

    link = LinkBase.find_by(id: opinion_about_link_id)
    return false if link.nil?

    luser_id = luser.original_id
    return true if link.creator_id == luser_id
    return true if link.parent.creator_id == luser_id
    return true if link.child.creator_id == luser_id

    false
  end
end
