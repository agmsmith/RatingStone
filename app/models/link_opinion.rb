# frozen_string_literal: true

class LinkOpinion < LinkBase
  alias_attribute :author, :parent
  alias_attribute :author_id, :parent_id
  alias_attribute :opinion_about_object, :child
  alias_attribute :opinion_about_object_id, :child_id
  alias_attribute :reason_why, :string1
end
