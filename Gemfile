source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
#gem "rails", "~> 7"

# AGMS20220102 Use a different branch of Rails since the release doesn't work with Ruby 3.1.0.  Once Rails 7.0.1 comes out, go back to the main Rails.
gem "rails", github: "rails/rails", branch: "7-0-stable"
gem "net-smtp", require: false # A missing dependency for the mail gem.

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use Sass to process CSS
gem "sassc-rails"

# CSS3 styles and javascript to build responsive, mobile-first web pages.
gem 'bootstrap-sass'

# For password hashing.
gem 'bcrypt'

# For generating fake names for making test users.
gem 'faker'

# For paginating long lists of things.
gem 'will_paginate'
gem 'bootstrap-will_paginate'

# For fancy text input language and formatting.
gem 'kramdown'

# For spelling out numbers as words (also vice versa) in Word Counter.
gem 'numbers_in_words'

# For showing the expansion changes made in Word Counter.
gem 'diffy'

group :development, :test do
  # Use the Puma web server [https://github.com/puma/puma]
  gem "puma"

  # Use sqlite3 as the database for Active Record
  gem "sqlite3"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  gem 'rubocop', require: false
  gem 'rubocop-shopify', require: false
end

group :production do
  # Use Postgresql as the database for Active Record
  gem 'pg'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "minitest"
  gem "minitest-reporters"
  gem "rails-controller-testing"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

