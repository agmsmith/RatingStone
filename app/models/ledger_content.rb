# frozen_string_literal: true

##
# Mostly an abstract class for content type things, like posts and pictures.
# They can all be displayed to the user and attached to groups, have replies
# and quotes etc.
class LedgerContent < LedgerBase
  alias_attribute :subject, :string1
  alias_attribute :summary_of_changes, :string2

  # Have to repeat these validations for subclasses.  Ugh!
  validates :subject, presence: true, length: { maximum: 255 }
  validates :summary_of_changes, length: { maximum: 255 }

  # When making a new post, you can also create it as belonging to several
  # groups and as a reply to several existing posts and as a quote (similar to
  # a reply but backwards).  To keep track of these groups and posts before the
  # record is saved (while editing an unsaved preview with the data passed back
  # and forth as HTML form parameters), we have these instance variable
  # Sets, containing strings with the ID numbers of the added objects.  Can
  # also use them to add more replies and groups and quotes when editing an
  # existing post.  The Set will keep them mostly unique.
  attr_accessor :new_groups, :new_quotes, :new_replytos

  after_initialize do |new_post|
    new_post.new_groups ||= Set.new
    new_post.new_quotes ||= Set.new
    new_post.new_replytos ||= Set.new
  end

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
  # How many other posts are quoting this one?
  def quote_count
    LinkReply.where(reply_post: self, deleted: false, approved_parent: true,
      approved_child: true).count
  end
end
