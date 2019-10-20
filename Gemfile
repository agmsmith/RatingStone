source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
# Use Puma as the app server
gem 'puma', '~> 3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.1'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4', require: false

group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 1.4'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.0', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '~> 4.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.1'
  gem 'spring-watcher-listen', '~> 2.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3'
  gem 'selenium-webdriver', '~> 3'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers', '~> 4.1'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'minitest', '~> 5'
  gem 'minitest-reporters', '~> 1'
end

group :production do
  gem 'pg', '~>1.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

