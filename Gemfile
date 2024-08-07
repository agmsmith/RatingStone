source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use Sass to process CSS
gem "sassc-rails"

# CSS3 styles and javascript to build responsive, mobile-first web pages.
gem 'bootstrap-sass'

# Need jQuery for BootStrap's Javascript to work.
gem 'jquery-rails'

# For password hashing.
gem 'bcrypt'

# For generating fake names for making test users.
gem 'faker'

# For paginating long lists of things.
gem 'pagy'

# For fancy text input language and formatting.
gem 'kramdown'

# For spelling out numbers as words (also vice versa) in Word Counter.
gem 'numbers_in_words'

# For showing the expansion changes made in Word Counter.
gem 'diffy'

group :development, :test do
  # Use the Puma web server [https://github.com/puma/puma]
  gem "puma"

  # Use sqlite3 as the database for Active Record.  Note version 1 since
  # ActiveRecord doesn't yet work with version 2 of the database adapter gem.
  # TODO: Update to version 2 of sqlite3 gem when ActiveRecord supports it.
  gem "sqlite3", "~> 1"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # For Visual Studio Code, needs Ruby language parser.
  # Remember to run "bundler config set --local without 'production'" in the
  # .ruby-lsp subdirectory.  Though now it seems to see these Gems in the main
  # project and doesn't create a separate .ruby-lsp directory.
  gem "ruby-lsp", require: false

  # Additional LSP extension that shows database fields when hovering the mouse
  # over an ActiveRecord object, but they only appear when the rails server is
  # running.
  gem "ruby-lsp-rails", require: false

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
  gem "minitest"
  gem "minitest-reporters"
  gem "rails-controller-testing"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

