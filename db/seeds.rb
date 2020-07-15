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
    name:  root_luser.string1,
    email: root_luser.string2,
    password: "SomePassword",
    password_confirmation: "SomePassword",
    admin: true,
    activated: true,
    activated_at: Time.zone.now)
  root_luser = root_user.ledger_user
  if (root_luser.id != 0)
    p "Bug: Root User doesn't have LedgerUser #0."
  end
end

# Create a system operator if needed.  Will have less priviledges than root.
if User.where(name: "System Operator").empty?
  sysop_user = User.create!(
    name:  "System Operator",
    email: "sysop@example.com",
    password: "SomePassword",
    password_confirmation: "SomePassword",
    admin: true,
    activated: true,
    activated_at: Time.zone.now)
  sysop_ledger = sysop_user.ledger_user # Will create ledger record.
  sysop_ledger.birthday = DateTime.new(2020,2,20,20,20,20) # Palindromic date.
  sysop_ledger.save!
end

# Create a dummy user to represent anonymous Internet browsers and search engines.
if User.where(name: "Anonymous Internet Browser").empty?
  internet_user = User.create!(
    name:  "Anonymous Internet Browser",
    email: "anonymous.internet@example.com",
    password: "SomePassword",
    password_confirmation: "SomePassword",
    admin: false,
    activated: true,
    activated_at: Time.zone.now)
  internet_ledger = internet_user.ledger_user # Will create ledger record.
  internet_ledger.birthday = DateTime.new(2020,2,2,2,2,2)
  internet_ledger.save!
end

# Generate a bunch of additional users, but not in test mode.
if !Rails.env.test?
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
    a_user.ledger_user
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
  3.times do
    content = Faker::Markdown.random
    users.each do |user|
      post = LedgerPost.create!(content: content, creator: user.ledger_user)
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
