source 'https://rubygems.org'

ruby '~> 3.3.0'

# Rails framework
gem 'rails', '~> 7.1.0'

# Database
gem 'sqlite3', '~> 1.4'

# Web server
gem 'puma', '>= 5.0'

# Assets
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# Authentication
gem 'bcrypt', '~> 3.1.7'

# JSON APIs
gem 'jbuilder'

# Timezone data for Windows
gem 'tzinfo-data', platforms: %i[windows jruby]

# Performance
gem 'bootsnap', require: false

group :development, :test do
  # Debugging
  gem 'debug', platforms: %i[mri windows]
  gem 'pry-byebug'
  
  # Testing
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  # Development tools
  gem 'web-console'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  # Testing tools
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 5.0'
end
