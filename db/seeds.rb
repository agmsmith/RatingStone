# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Create the root LedgerBase object, which is its own creator.

ActiveRecord::Base.connection.execute('INSERT into ledger_bases (id, string1, string2, text1, creator_id, created_at, updated_at) VALUES (0, "Root LedgerBase Object", "agmsmith@ncf.ca", "The special root object which we need to manually create with a creator id of itself.  Then initial system objects can be created with it as their creator.  AGMS20200206", 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);')

# Create the system operator.
sysop_user = User.create!(
  name:  "System Operator",
  email: "SomeEMail@SomeDomain.com",
  password: "SomePassword",
  password_confirmation: "SomePassword",
  admin: true,
  activated: true,
  activated_at: Time.zone.now)

LedgerBase.create!(
  string1: sysop_user.name,
  number1: sysop_user.id,
  creator_id: 0)

# Generate a bunch of additional users.
#9.times do |n|
#  name  = Faker::Name.name
#  email = "example-#{n+1}@railstutorial.org"
#  password = "password"
#  User.create!(
#    name: name,
#    email: email,
#    password: password,
#    password_confirmation: password,
#    activated: true,
#    activated_at: Time.zone.now)
#end

## Generate microposts for a subset of users.
#users = User.order(:created_at).take(6)
#5.times do
#  content = Faker::Lorem.sentence(word_count: 5)
#  users.each { |user| user.microposts.create!(content: content) }
#end

## Create following relationships.
#users = User.all
#user  = users.first
#following = users[2..5]
#followers = users[3..6]
#following.each { |followed| user.follow(followed) }
#followers.each { |follower| follower.follow(user) }

