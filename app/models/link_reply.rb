# frozen_string_literal: true

class LinkReply < LinkBase
  alias_attribute :original_post, :parent
  alias_attribute :original_post_id, :parent_id
  alias_attribute :reply_post, :child
  alias_attribute :reply_post_id, :child_id

  ##
  # Besides the creator of the link, the users who can approve either end of
  # the link are allowed to delete it (creator_owner? for links is mostly used
  # for delete permission).  So if someone attaches their reply to your post,
  # you can unapprove it or even delete the link to it.
  def creator_owner?(luser)
    return true if super
    return true if permission_to_change_parent_approval(luser)
    permission_to_change_child_approval(luser)
  end
end
