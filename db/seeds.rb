# This file should contain all the record creation needed to seed the database
# with its default values.  The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).  We've also hacked
# up the test/test_helper.rb to automatically seed test databases too.
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# If needed, create the root LedgerBase object, which is its own creator.
unless LedgerBase.any?
  ActiveRecord::Base.connection.execute("INSERT into ledger_bases (id, type, number1, string1, string2, text1, creator_id, original_id, rating_points_spent_creating, rating_points_boost_self, current_meh_points, original_ceremony, current_ceremony, date1, created_at, updated_at) VALUES (0, 'LedgerUser', 0, 'Root LedgerBase Object', 'agmsmith@ncf.ca', 'The special root object/user which we need to manually create with a creator id of itself.  Then initial system objects can be created with it as their creator.  AGMS20200206', 0, 0, 0.0, 0.0, 1000.0, 0, 0, '0001-01-01 00:00:00', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);")
  root_luser = LedgerBase.find(0)
  root_user = User.create!(
    id: 0,
    ledger_user_id: 0,
    name: root_luser.string1,
    email: root_luser.string2,
    password: "SomePassword",
    password_confirmation: "SomePassword",
    admin: true)
end

# Create system operators and other special users, they are users with known
# record ID numbers (no need to do a database lookup to see if someone is a
# sysop).  Start off as unuseable (unactivated and no way to send an
# activation e-mail) users.  Don't do in test mode, where record IDs are random
# numbers (hashes actually, see Fixture system), not sequential.  Also do
# set_up_new_user after the magic number LedgerUsers are created to avoid
# creating auxiliary LedgerBase records which would mess up the numbering.
# Magic numbers 1 to 9 are sysops.  10 is the anonymous user for not logged in
# people (like search engines).
if !Rails.env.test?
  (1..9).each do |i|
    unless LedgerUser.find_by(id: i)
      LedgerUser.create!(creator_id: 0,
        name: "System Operator #{i}",
        email: "sysop#{i}@example.com",
        rating_points_spent_creating: 0.0)
    end
  end

  # Create a catch-all user #10 to represent anonymous Internet browsers.
  unless LedgerUser.find_by(id: 10)
    anonymous_luser = LedgerUser.create!(creator_id: 0,
      name: "Anonymous Internet Browser",
      email: "anonymous.internet@example.com",
      rating_points_spent_creating: 0.0)
  end

  # Add a standard bonus description.
  bonus_for_activation = LedgerPost.where(subject: "Bonus for Activation")
    .order(created_at: :asc).first
  unless bonus_for_activation
    bonus_for_activation = LedgerPost.create!(creator_id: 0,
      rating_points_spent_creating: 10.0, rating_points_boost_self: 9.0,
      rating_direction_self: "U", subject: "Bonus for Activation",
      content: "Once you have activated your account, by e-mail verification, " \
        "you get a **10 Point** allowance after each awards ceremony " \
        "(usually a week apart).\n\nNote that over time the bonus will fade and " \
        "eventually expire, and you'll have to verify your e-mail again.",
      summary_of_changes: "Initial version, AGMS20220301.")
  end

  # Add a miscellaneous bonus description.
  bonus_for_miscellaneous = LedgerPost.where(subject: "Bonus for Miscellaneous")
    .order(created_at: :asc).first
  unless bonus_for_miscellaneous 
    bonus_for_miscellaneous = LedgerPost.create!(creator_id: 0,
      rating_points_spent_creating: 10.0, rating_points_boost_self: 9.0,
      rating_direction_self: "U", subject: "Bonus for Miscellaneous",
      content: "Here's a bonus for miscellaneous things, like giving points to " \
        "the initial user in the database.",
      summary_of_changes: "Initial version, AGMS20221226.")
  end

  # Big bonus for the new root user, test mode instead uses fixtures for this.
  if root_luser # If first time, otherwise root_luser is nil.
    LinkBonusUnique.create!(creator_id: 0, bonus_user_id: 0,
      bonus_explanation: bonus_for_miscellaneous, bonus_points: 1000,
      expiry_ceremony: 100000,
      rating_points_spent: 10 + 1.0 / 16, reason: "Root should have a bonus " \
        "to get some starting points, particularly when all the points are " \
        "recalculated.",
      approved_parent: true, approved_child: true)
  end

  # Check that we got the right ID numbers for the magic users, and now create
  # associated new user records, which would have interfered with sequentially
  # creating LedgerUser records.
  (1..10).each do |i|
    magic_luser = LedgerUser.find(i)
    magic_user = magic_luser.create_user
    magic_luser.set_up_new_user # Makes home group etc.  Safe to call again.
    if magic_user.id != i
      raise "Bug: Wrong record ID #{magic_user.id} for User for #{magic_luser}."
    end
    name = if i < 10
      "System Operator #{i}"
    elsif i == 10
      "Anonymous Internet Browser"
    else
      "Bad Name."
    end
    if magic_user.name != name
      raise "Bug: Wrong name for user record created from #{magic_luser}."
    end
  end
end

# Create Mike Davison, the first person to set up an account, though he
# doesn't use it.
if User.where(name: "Mike Davison").empty?
  pw = SecureRandom.hex(35)
  mike_user = User.create!(
    name:  "Mike Davison",
    email: "davisonspeaking@gmail.com",
    password: pw,
    password_confirmation: pw,
    admin: false)
  mike_user.update_attribute(:password_digest,
   '$2a$12$F4kOjn3bCMtcP/ebvORdGOnkDhEhSAhnq/2TahVSNF4TMxaGCHhBe')
  mike_user.create_or_get_ledger_user
  mike_user.activate
end

# Generate a bunch of additional users and data, but only in development.
if Rails.env.development?
  # Make four groups.  GOne, GTwo, GThree, and GMany a subgroup of GTwo & GThree.
  group_names = %w[GOne GTwo GThree GMany]
  group_records = []
  3.times do |i|
    group_records.push (LedgerFullGroup.create!(name: group_names[i],
      description: "Group number *#{i + 1}*.", creator_id: 0))
  end
  group_records.push (LedgerSubgroup.create!(name: group_names.last,
    description: "A _Subgroup_, under GTwo and GThree, delegates to GThree.  " \
    "This one also has a very long description so we can see how well it " \
    "gets formatted in the group listings.  Note that groups have their " \
    "description in Kramdown markup format.  Line break in Kramdown:  \n" \
    "![RatingStone Icon](/apple-touch-icon.png){:align=\"left\"}That should " \
    "make it more interesting.  There should also be a pinned post to more " \
    "graphically describe the group, though I think Kramdown also lets you " \
    "embed pictures.", creator_id: 0))
  # Put the subgroup under GTwo and GThree.  But delegate members to GThree.
  LinkSubgroup.create!(parent: group_records[1], child: group_records[3],
    creator_id: 0)
  LinkSubgroup.create!(parent: group_records[2], child: group_records[3],
    creator_id: 0)
  LinkGroupRoleDelegation.create!(parent: group_records[2],
    child: group_records[3], creator_id: 0)

  12.times do |n|
    name  = Faker::Name.name
    email = "example-#{n+1}@railstutorial.org"
    pw = SecureRandom.hex(35)
    a_user= User.create!(
      name: name,
      email: email,
      password: pw,
      password_confirmation: pw)
    a_user.activate
    luser = a_user.create_or_get_ledger_user
    # Add the person to one of three groups.  Role based on iteration level.
    LinkRole.create!(group: group_records[n % 3], user: luser,
      priority: n / 3 * 10 + 10, creator_id: 0, rating_points_spent: 10.0,
      rating_points_boost_parent: 0.0, rating_points_boost_child: 10.0,
      approved_parent: true, approved_child: true)
  end

  # Make some LedgerPosts for some users.  Use Markdown formatting.  Arrange
  # them as a graph of replies.
  users = User.order(created_at: :desc).take(10)
  posts = []
  40.times do |i|
    subject = Faker::Book.title
    content = Faker::Markdown.random
    user = users.sample
    luser = user.create_or_get_ledger_user
    lgroup = luser.home_group
    lpost = LedgerPost.create!(subject: subject, content: content,
      creator: luser)
    LinkGroupContent.create!(parent: lgroup, child: lpost, creator: luser,
      approved_parent: true, approved_child: true)
    previous_lpost = posts.sample
    if previous_lpost # Make this a reply to some previous post.
      LinkReply.create!(parent: previous_lpost, child: lpost, creator: luser,
        approved_parent: true, approved_child: true)
    end
    posts << lpost
  end
  # Add a cycle to the reply graph; first post is a reply to the last post.
  LinkReply.create!(parent: posts.last, child: posts.first, creator_id: 0,
    approved_parent: true, approved_child: true)

  # And for extra fun, make it a reply to a second post too.
  LinkReply.create!(parent: posts.second_to_last, child: posts.first,
    creator_id: 0, approved_parent: true, approved_child: true)

  # Graphical post.  Need to use URL that starts with a slash, or it won't work
  # when viewed in some sub-pages.
  post = LedgerPost.create!(subject: "Embedded Picture Test", content:
    "![RatingStone Icon](/apple-touch-icon.png){:align=\"right\"}Here is a " \
    "post with Kramdown markup containing an image, set to float to the right.",
    creator_id: 0)
  LinkGroupContent.create!(parent: group_records[3], child: post, creator_id: 0,
    approved_parent: true, approved_child: true)

  # Make all links approved, not the usual case.
  unapproved_count = LinkBase.where(approved_parent: false).
    or(LinkBase.where(approved_child: false)).count
  puts "#{LedgerBase.count} Ledger Objects created, #{LinkBase.count} links, " \
    "including #{unapproved_count} unapproved links."
end
