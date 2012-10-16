source 'https://rubygems.org'

gem 'rails', '3.2.2'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Storage
gem 'pg'
gem 'foreigner'
gem 'aws-s3'
gem 'roo' #excel parser
gem 'docsplit'
gem 'rubyXL'
gem 'devise'
gem 'devise-async'

gem 'lama', :git => 'https://github.com/gangleton/lama.git'
gem 'savon'
gem "httpclient", "~> 2.1.5"

gem 'delayed_job_active_record'

# GIS 
gem 'rgeo'
gem 'rgeo-geojson'
gem 'activerecord-postgis-adapter'
gem 'rgeo-shapefile'

# Templates
gem 'haml'
gem 'jquery-rails'
gem 'rails3-jquery-autocomplete'
gem 'kaminari'

gem 'thin'

gem 'newrelic_rpm'

gem 'debugger'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end


# Testing
group :test, :development do
  gem "test-unit"
	gem "rspec-rails", '>= 2.9.0' 
	gem "shoulda"

	gem "capybara"
	
	gem "factory_girl_rails"
  gem "faker"

  gem "simplecov"
end

group :development do
  gem 'awesome_print'
end

group :test do
  gem "rake"
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
