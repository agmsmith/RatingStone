# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  validates :content, presence: true

  # When making a new post, you can also create it as belonging to several
  # groups and as a reply to several existing posts.  To keep track of these
  # groups and posts before the record is saved (while editing an unsaved
  # preview with the data passed back and forth as HTML form parameters), we
  # have these two instance variable sets.  Can also use them to add more
  # replies and groups when editing an existing post.  The Set will keep them
  # unique.
  attr_accessor :new_groups, :new_replytos

  after_initialize do |new_post|
    new_post.new_groups ||= Set.new
    new_post.new_replytos ||= Set.new
  end
end
