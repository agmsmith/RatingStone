# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  validates :content, presence: true

  # When making a new post, you can also create it as belonging to several
  # groups and as a reply to several existing posts.  To keep track of these
  # groups and posts before the record is saved (while editing an unsaved
  # preview), we have these two instance variable arrays.  Can also use them to
  # add more replies and groups when editing an existing post.
  attr_accessor :new_groups, :new_replytos

  after_initialize do |new_post|
    new_post.new_groups ||= []
    new_post.new_replytos ||= []
  end
end
