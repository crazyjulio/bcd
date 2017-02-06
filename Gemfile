source 'http://rubygems.org'

ruby '2.2.6'

gem 'rails', '4.2.7'
gem 'activerecord-session_store'
gem 'protected_attributes'
gem 'devise', '3.5.10'
gem 'aws-sdk'
gem 'aws-sdk-rails'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'hpricot'
gem 'ruby_parser'
gem 'carrierwave'
gem 'carrierwave_backgrounder'
gem 'fog'
gem 'pg'
gem 'mini_magick'
gem 'kaminari'
gem 'nested_form'
gem 'twitter'
gem 'exception_notification'
gem "haml-rails"
gem 'jquery-rails'
gem 'rake'

gem 'resque'
gem 'resque_mailer'
gem 'resque-status'
gem 'heroku-api'
gem 'roboto'
gem 'sitemap_generator'
gem 'responders', '~> 2.0'

#assets
gem 'sass-rails'
gem 'compass-rails'
gem 'compass-blueprint'
gem 'uglifier'
gem 'sprockets'
gem 'asset_sync'

# Use unicorn as the web server
#gem 'unicorn'
gem 'thin'
# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

group :development, :test do
  gem 'dotenv-rails'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rb-fsevent', :require => false #if RUBY_PLATFORM =~ /darwin/i
  gem 'guard-livereload'
  gem 'guard-compass', :require => false
  gem 'rack-mini-profiler'
  gem "nifty-generators"
  #gem 'guard-rspec'
  gem "factory_girl_rails"
  gem "factory_girl_generator"
  gem "rspec-rails", '~> 3.0'
  gem 'rspec-activemodel-mocks'
  gem 'simplecov', :require => false
  #gem 'brakeman'
  gem 'metric_fu', git: 'https://github.com/bergholdt/metric_fu.git'
  gem 'mail_view', "~> 2.0.4"
  gem 'foreman'
  gem 'awesome_print', require: 'ap'
  gem 'pry-byebug'
  gem 'bullet'
  gem 'gemsurance'
  gem 'pry'
end

group :development do
  gem 'web-console', '~> 2.0'
end

group :test do
  gem 'mock_redis'
  gem 'database_cleaner'
end

group :profile do
  gem 'ruby-prof'
end

group :production, :staging do
  gem 'rails_12factor'
  #best to keep this at the bottom:
  gem 'newrelic_rpm'
  gem 'lograge'
end
