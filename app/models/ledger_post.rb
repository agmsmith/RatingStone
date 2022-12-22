# frozen_string_literal: true

class LedgerPost < LedgerBase
  alias_attribute :subject, :string1
  alias_attribute :summary_of_changes, :string2
  alias_attribute :content, :text1

  # Watch out for replies which use multiple versions, this works only for
  # original version ID numbers.  Use quotes_good, replies_good instead.
  has_many :link_replies, class_name: :LinkReply, foreign_key: :parent_id
  has_many :replies, through: :link_replies, source: :child
  has_many :link_quotes, class_name: :LinkReply, foreign_key: :child_id
  has_many :quotes, through: :link_quotes, source: :parent

  validates :content, presence: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :summary_of_changes, length: { maximum: 255 }

  # When making a new post, you can also create it as belonging to several
  # groups and as a reply to several existing posts and as a quote (similar to
  # a reply but backwards).  To keep track of these groups and posts before the
  # record is saved (while editing an unsaved preview with the data passed back
  # and forth as HTML form parameters), we have these instance variable
  # Arrays, containing tuples (hashes) with the ID numbers (:ID), direction
  # letter code (:UMD) and points (:Points) requested for the added objects.
  # Can also use them to add more replies and groups and quotes when editing
  # an existing post.  Maximum of 10 tuples per array, due to single digit for
  # index.
  attr_accessor :new_groups, :new_quotes, :new_replytos

  after_initialize do |new_post|
    new_post.new_groups ||= []
    new_post.new_quotes ||= []
    new_post.new_replytos ||= []
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
  # How many other posts are quoting this one?  Well, actually the original one.
  def quote_count
    LinkReply.where(reply_post_id: original_version_id, deleted: false,
      approved_parent: true, approved_child: true).count
  end

  ##
  # Return a relation with the original versions of quotes of this post, only
  # for quotes which are still valid (not deleted, both link ends approved).
  def quotes_good
    LedgerBase.where(id:
      original_version.link_quotes.where(deleted: false, approved_parent: true,
      approved_child: true).select(:prior_post_id),
      deleted: false).order(:created_at)
  end

  ##
  # How many replies did this post get?
  def reply_count
    LinkReply.where(prior_post_id: original_version_id, deleted: false,
      approved_parent: true, approved_child: true).count
  end

  ##
  # Return a relation with the original versions of replies of this post, only
  # for replies which are still valid (not deleted, both link ends approved).
  def replies_good
    LedgerBase.where(id:
      original_version.link_replies.where(deleted: false, approved_parent: true,
      approved_child: true).select(:reply_post_id),
      deleted: false).order(:created_at)
  end
end
