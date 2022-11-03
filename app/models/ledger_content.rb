# frozen_string_literal: true

##
# Mostly an abstract class for content type things, like posts and pictures.
# They can all be displayed to the user and attached to groups, have replies.
class LedgerContent < LedgerBase
  alias_attribute :subject, :string1

  # Have to repeat these validations for subclasses.  Ugh!
  validates :subject, presence: true, length: { maximum: 255 }

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    "#{subject.truncate(40).tr("\n", " ")}, " \
      "by: ##{creator_id} #{creator.latest_version.name.truncate(20)}"
  end

  ##
  # How many replies did this post get?
  def reply_count
    LinkReply.where(prior_post: self, deleted: false, approved_parent: true,
      approved_child: true).count
  end

  ##
  # How many other posts have this one as a reply?
  def quote_count
    LinkReply.where(reply_post: self, deleted: false, approved_parent: true,
      approved_child: true).count
  end
end
