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
if LedgerBase.all.empty?
  ActiveRecord::Base.connection.execute("INSERT into ledger_bases (id, type, number1, string1, string2, text1, creator_id, original_id, date1, created_at, updated_at) VALUES (0, 'LedgerUser', 0, 'Root LedgerBase Object', 'agmsmith@ncf.ca', 'The special root object/user which we need to manually create with a creator id of itself.  Then initial system objects can be created with it as their creator.  AGMS20200206', 0, 0, '0001-01-01 00:00:00', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);")
  root_luser = LedgerBase.find(0)
  root_user = User.create!(
    id: 0,
    ledger_user_id: 0,
    name: root_luser.string1,
    email: root_luser.string2,
    password: "SomePassword",
    password_confirmation: "SomePassword",
    admin: true)
  root_luser = root_user.ledger_user
  if (root_luser.id != 0)
    raise "Bug: Root User doesn't have LedgerUser #0 #{root_luser}."
  end
  root_user.activate
end

# Create system operators, they are users with ID less than 10 (no need to do
# a database lookup to see if someone is a sysop).  Will have less priviledges
# than root.  Start off as unuseable (unactivated and no way to send an
# activation e-mail) users.  Don't do in test mode, where record IDs are random
# numbers (hashes actually, see Fixture system), not sequential.
if !Rails.env.test?
  (1..9).each do |i|
    unless User.exists?(name: "System Operator #{i}")
      pw = SecureRandom.hex(35)
      sysop_luser = LedgerUser.create!(creator_id: 0,
        name: "System Operator #{i}", email: "sysop#{i}@example.com")
      sysop_user = User.create!(
        name: sysop_luser.name,
        email: sysop_luser.email,
        password: pw,
        password_confirmation: pw,
        admin: true)
      sysop_user.ledger_user_id = sysop_luser.id
      sysop_user.save!
    end
  end

  # Check that we got the right ID numbers for the sysops, and now create the
  # associated new user records, which would have interfered with sequentially
  # creating LedgerUser records.
  (1..9).each do |i|
    sysop_user = User.find_by(name: "System Operator #{i}")
    sysop_luser = sysop_user.ledger_user
    if (sysop_luser.original_version_id != i)
      raise "Bug: Sysop User #{i} #{sysop_luser} doesn't have LedgerUser ##{i}."
    end
    sysop_luser.set_up_new_user
  end
end

# Create a dummy user to represent anonymous Internet browsers and search engines.
if User.where(name: "Anonymous Internet Browser").empty?
  pw = SecureRandom.hex(35)
  internet_user = User.create!(
    name:  "Anonymous Internet Browser",
    email: "anonymous.internet@example.com",
    password: pw,
    password_confirmation: pw,
    admin: false)
  internet_ledger = internet_user.ledger_user # Will create ledger record.
  internet_ledger.birthday = DateTime.new(2020,2,2,2,2,2)
  internet_ledger.save!
  internet_user.activate
end

# Generate a bunch of additional users and data, but not in test mode.
if !Rails.env.test?
  # Make four groups.  GOne, GTwo, GThree, and GMany a subgroup of GTwo & GThree.
  group_names = %w[GOne GTwo GThree GMany]
  group_records = []
  3.times do |i|
    group_records.push (LedgerFullGroup.create!(name: group_names[i],
      description: "Group number #{i + 1}.", creator_id: 0))
  end
  group_records.push (LedgerSubgroup.create!(name: group_names.last,
    description: "A Subgroup, under GTwo and GThree, delegates to GThree",
    creator_id: 0))
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
    password = "password"
    a_user= User.create!(
      name: name,
      email: email,
      password: password,
      password_confirmation: password,
      activated: true,
      activated_at: Time.zone.now)
    luser = a_user.ledger_user
    # Add the person to one of three groups.  Role based on iteration level.
    LinkRole.create!(group: group_records[n % 3], user: luser,
      priority: n / 3 * 10 + 10, creator_id: 0)
  end

  # Generate microposts for a subset of users.
  users = User.order(:created_at).take(6)
  5.times do
    content = Faker::Lorem.sentence(word_count: 5)
    users.each { |user| user.microposts.create!(content: content) }
  end
  user = User.last
  40.times do
    user.microposts.create!(content: Faker::Company.catch_phrase)
  end

  # Make some LedgerPosts for some users.  Use Markdown formatting.
  users = User.order(:created_at).take(4)
  4.times do |i|
    content = Faker::Markdown.random
    users.each do |user|
      post = LedgerPost.create!(content: content, creator: user.ledger_user)
      LinkGroupContent.create!(parent: group_records[i], child: post,
        creator: user.ledger_user)
      post2 = post.append_version
      post2.content = "Sorry, I meant " + Faker::Lorem.sentence(word_count: 8)
      post2.save!
      post.reload
      post3 = post.append_version
      post3.content = "Oops, that was " + Faker::Lorem.sentence(word_count: 6)
      post3.save!
    end
  end

  # Create following relationships.
  users = User.all
  user  = users.first
  following = users[2..5]
  followers = users[3..6]
  following.each { |followed| user.follow(followed) }
  followers.each { |follower| follower.follow(user) }
end
