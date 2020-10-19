# frozen_string_literal: true

class LinkReply < LinkBase
  alias_attribute :original_post, :parent
  alias_attribute :original_post_id, :parent_id
  alias_attribute :reply_post, :child
  alias_attribute :reply_post_id, :child_id
end
