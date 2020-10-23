# frozen_string_literal: true

class LedgerPost < LedgerContent
  alias_attribute :content, :text1
  alias_attribute :summary_of_changes, :string2

  validates :content, presence: true
  validates :summary_of_changes, length: { maximum: 255 }
  # Have to repeat these validations for subclasses.  Ugh!
  validates :subject, presence: true, length: { maximum: 255 }

  # When making a new post, you can also create it as belonging to several
  # groups and as a reply to several existing posts.  To keep track of these
  # groups and posts before the record is saved (while editing an unsaved
  # preview with the data passed back and forth as HTML form parameters), we
  # have these two instance variable Sets, containing strings with the ID
  # numbers of the added objects.  Can also use them to add more replies and
  # groups when editing an existing post.  The Set will keep them mostly unique.
  attr_accessor :new_groups, :new_replytos

  after_initialize do |new_post|
    new_post.new_groups ||= Set.new
    new_post.new_replytos ||= Set.new
  end
end
