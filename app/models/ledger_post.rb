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
  # Class method to find all active descendants of a given bunch of LedgerPosts,
  # given arguments to "where" to select the initial LedgerPosts.  Returns a
  # relation which you can query (useful for pagination).  The relation also
  # outputs a path attribute which is a string consisting of id numbers, each
  # 10 digits in brackets (0000000123), separated by commas.
  #
  # Notes on using recursive SQL and tree traversal in Rails:
  #
  # From https://hashrocket.com/blog/posts/recursive-sql-in-activerecord
  # they suggest hooking into where("#{table_name}.id IN <insert Recursive SQL
  # here, returning a list of ID numbers>")  They also have the good idea of
  # making a function to generate the recursive SQL.
  #
  # https://www.itcodar.com/sql/rails-raw-sql-example.html uses the #from()
  # method to insert the SQL into an ActiveRecord::Relation.  You just have
  # to return something that looks like the usual record structure you're using,
  # and conveniently any extra fields (like the path) become attributes in the
  # ActiveRecord objects.
  #
  # Some examples of making SQL recursive code in https://stackoverflow.com/questions/11664233/how-to-make-a-recursive-function-in-rails-that-will-return-all-children-of-a-par
  #
  # The best examples for recursive SQL, including cycle detection, traversal
  # ordering is from the PostgreSQL manual itself:
  # https://www.postgresql.org/docs/14/queries-with.html#QUERIES-WITH-RECURSIVE
  class << self
    def tree_of_quotes(*args)
      # Generate SQL to select the starting point of the search, starts out like
      # SELECT "ledger_bases".* FROM "ledger_bases" WHERE
      # "ledger_bases"."type" = 'LedgerPost' AND "ledger_bases"."id" = 93
      # We want to insert an initial path in there, before the FROM and
      # rework it to use only ID numbers and path during iteration.
      # SELECT "ledger_bases"."id" AS "post_id",
      # path-for-starting-id AS path FROM "ledger_bases"
      # WHERE "ledger_bases"."type" = 'LedgerPost' AND "ledger_bases"."id" = 93
      # Note funky SUBSTRING and LENGTH and || concatenation is code that works
      # in both Sqlite3 and PostgreSQL; adds leading zeroes to ID number.
      starting_select_sql = where(*args).to_sql
        .sub(/\.\*/, ".id AS post_id, '(' || " \
          "SUBSTRING('0000000000' || ledger_bases.id, " \
          "LENGTH('x' || ledger_bases.id))" \
          "|| ')' AS path")

      # Now do the recursive search.  The path is the history of LedgerPost
      # ID numbers to get to the given node, and is sorted later to give
      # breadth first ordering of posts.  For Sqlite3 compatibility, we're
      # using a string for the path.  PostgreSQL could use an ARRAY datatype.
      # Anyway, each number is padded up to 10 digits so that sort order isn't
      # mangled by the number of digits.  Brackets are around the numbers to
      # make a string search for a particular number easier.  Each iteration
      # we find LedgerPosts that are quotes of the previously found LedgerPosts
      # and add them to the result, storing just their ID numbers and their
      # path.  Skip ones where their ID is already in the path (they are part
      # of a cycle in the graph and we've already gotten to them).

      select("*").from("(#{<<~LONGSQLQUERY}) AS ledger_bases")
        WITH RECURSIVE ascent(post_id, path) AS (
          #{starting_select_sql}
        UNION ALL
          SELECT ledger_bases.id AS post_id,
            (ascent.path || ',(' || SUBSTRING('0000000000' || ledger_bases.id,
            LENGTH('x' || ledger_bases.id)) || ')') AS "path"
          FROM ascent, ledger_bases, link_bases link
          WHERE link.child_id = ascent.post_id AND link.type = 'LinkReply' AND
            link.approved_parent = TRUE AND link.approved_child = TRUE AND
            link.deleted = FALSE AND
            ledger_bases.id = link.parent_id AND ledger_bases.deleted = FALSE AND
            (NOT path LIKE '%(' || SUBSTRING('0000000000' ||
            link.parent_id, LENGTH('x' || link.parent_id)) || ')%')
        )
        SELECT ledger_bases.*, ascent.path
          FROM ascent, ledger_bases
          WHERE ledger_bases.id = ascent.post_id
          ORDER BY path DESC
      LONGSQLQUERY
    end
  end

  ##
  # Find all the replies to a post, see tree_of_quotes for more docs.
  class << self
    def tree_of_replies(*args)
      starting_select_sql = where(*args).to_sql
        .sub(/\.\*/, ".id AS post_id, '(' || " \
          "SUBSTRING('0000000000' || ledger_bases.id, " \
          "LENGTH('x' || ledger_bases.id))" \
          "|| ')' AS path")

      select("*").from("(#{<<~LONGSQLQUERY}) AS ledger_bases")
        WITH RECURSIVE descent(post_id, path) AS (
          #{starting_select_sql}
        UNION ALL
          SELECT ledger_bases.id AS post_id,
            (descent.path || ',(' || SUBSTRING('0000000000' || ledger_bases.id,
            LENGTH('x' || ledger_bases.id)) || ')') AS "path"
          FROM descent, ledger_bases, link_bases link
          WHERE link.parent_id = descent.post_id AND link.type = 'LinkReply' AND
            link.approved_parent = TRUE AND link.approved_child = TRUE AND
            link.deleted = FALSE AND
            ledger_bases.id = link.child_id AND ledger_bases.deleted = FALSE AND
            (NOT path LIKE '%(' || SUBSTRING('0000000000' ||
            link.child_id, LENGTH('x' || link.child_id)) || ')%')
        )
        SELECT ledger_bases.*, descent.path
          FROM descent, ledger_bases
          WHERE ledger_bases.id = descent.post_id
          ORDER BY path
      LONGSQLQUERY
    end
  end

  ##
  # Find all the quotes and replies to a post.  Can't just stick together
  # the Relations from tree_of_replies and tree_of_quotes because the outputs
  # aren't compatible for some reason.  So duplicate code and UNION it, and
  # keep ascent and descent paths separate so we can sort them in different
  # orders so that they read nicely chronologically.
  class << self
    def tree_of_quotes_and_replies(*args)
      select("*").from("(#{<<~LONGSQLQUERY}) AS ledger_bases")
        WITH RECURSIVE starting_state(post_id, path) AS (
          #{where(*args).to_sql.sub(/\.\*/,
            ".id AS post_id, '(' || " \
            "SUBSTRING('0000000000' || ledger_bases.id, " \
            "LENGTH('x' || ledger_bases.id)) || ')' AS path")}
        ),
        ascent(post_id, path) AS (
          SELECT * FROM starting_state
        UNION ALL
          SELECT ledger_bases.id AS post_id,
            (ascent.path || ',(' || SUBSTRING('0000000000' || ledger_bases.id,
            LENGTH('x' || ledger_bases.id)) || ')') AS path
          FROM ascent, ledger_bases, link_bases link
          WHERE link.child_id = ascent.post_id AND link.type = 'LinkReply' AND
            link.approved_parent = TRUE AND link.approved_child = TRUE AND
            link.deleted = FALSE AND
            ledger_bases.id = link.parent_id AND ledger_bases.deleted = FALSE AND
            (NOT path LIKE '%(' || SUBSTRING('0000000000' ||
            link.parent_id, LENGTH('x' || link.parent_id)) || ')%')
        ),
        descent(post_id, path) AS (
          SELECT * FROM starting_state
        UNION ALL
          SELECT ledger_bases.id AS post_id,
            (descent.path || ',(' || SUBSTRING('0000000000' || ledger_bases.id,
            LENGTH('x' || ledger_bases.id)) || ')') AS path
          FROM descent, ledger_bases, link_bases link
          WHERE link.parent_id = descent.post_id AND link.type = 'LinkReply' AND
            link.approved_parent = TRUE AND link.approved_child = TRUE AND
            link.deleted = FALSE AND
            ledger_bases.id = link.child_id AND ledger_bases.deleted = FALSE AND
            (NOT path LIKE '%(' || SUBSTRING('0000000000' ||
            link.child_id, LENGTH('x' || link.child_id)) || ')%')
        )
        SELECT ledger_bases.*,
          ascent.path AS path_a, '' AS path_d, ascent.path AS path
          FROM ascent, ledger_bases
          WHERE ledger_bases.id = ascent.post_id
        UNION ALL
        SELECT ledger_bases.*,
          '' AS path_a, descent.path AS path_d, descent.path AS path
          FROM descent, ledger_bases
          WHERE ledger_bases.id = descent.post_id
        ORDER BY path_a DESC, path_d ASC
      LONGSQLQUERY
    end
  end

  ##
  # Return some user readable context for the object.  Things like the name of
  # the user if this is a user object.  Used in error messages.  Empty string
  # for none.
  def context_s
    "#{subject.truncate(40).tr("\n", " ")}, " \
      "by ##{creator_id}"
  end

  ##
  # How many other posts are quoting this one?  Well, actually the original one.
  def quote_count
    LinkReply.where(
      reply_post_id: original_version_id,
      deleted: false,
      approved_parent: true,
      approved_child: true,
    ).count
  end

  ##
  # Return a relation with the original versions of quotes of this post, only
  # for quotes which are still valid (not deleted, both link ends approved).
  def quotes_good
    LedgerBase.where(
      id: original_version.link_quotes
            .where(deleted: false, approved_parent: true, approved_child: true)
            .select(:prior_post_id),
      deleted: false,
    ).order(:created_at)
  end

  ##
  # How many replies did this post get?
  def reply_count
    LinkReply.where(
      prior_post_id: original_version_id,
      deleted: false,
      approved_parent: true,
      approved_child: true,
    ).count
  end

  ##
  # Return a relation with the original versions of replies of this post, only
  # for replies which are still valid (not deleted, both link ends approved).
  def replies_good
    LedgerBase.where(
      id: original_version.link_replies
            .where(deleted: false, approved_parent: true, approved_child: true)
            .select(:reply_post_id),
      deleted: false,
    ).order(:created_at)
  end
end
