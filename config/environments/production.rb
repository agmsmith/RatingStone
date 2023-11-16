require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  config.require_master_key = true

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Enable server timing
  config.server_timing = true

  # Enable caching.  Not!  Because everything is dynamically generated, and if it mis-caches...
  config.action_controller.enable_fragment_cache_logging = true
  config.cache_store = :null_store
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{2.days.to_i}"
  }
  config.action_controller.perform_caching = false

  # Enable static file serving from the `/public` folder (turn off if using NGINX/Apache for it).
  config.public_file_server.enabled = false

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Suppress logger output for asset requests.  Not!
  config.assets.quiet = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = false

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Actually, we don't want that - allow HTTPS but don't require it, so older browsers work.
  config.force_ssl = false

  # Log to STDOUT by default, STDERR is better (shows up in web server),
  # and even better is nothing (shows up in logs/production.log file).
  #config.logger = ActiveSupport::Logger.new(STDOUT)
  #  .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
  #  .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "rating_stone_production"

  # Store uploaded files on the local file system (see config/storage.yml
  # for options).
  # config.active_storage.service = :local

  # Fix for database busy with multithreaded ActiveStorage purges and SQLite3
  # database; run the job immediately, don't actually queue it for later.
  # config.active_job.queue_adapter = :inline

  config.action_mailer.perform_caching = false

  host = 'ratingstone.agmsmith.ca'
  config.action_mailer.default_url_options = { host: host, protocol: 'http' }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true

  # Use :test for internal testing, :smtp for normal mail server.
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    :address => 'smtp.gmail.com',
    :port => '587',
    :authentication => :plain,
    :user_name => 'agmsrepsys@gmail.com',
    :password => 'SomePassword',
    :enable_starttls_auto => true,
    :domain => host
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Print deprecation notices to the Rails logger and standard error.
  config.active_support.report_deprecations = true
  config.active_support.deprecation = [:log, :stderr]

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Do not dump schema after migrations.  Not!
  config.active_record.dump_schema_after_migration = true

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
