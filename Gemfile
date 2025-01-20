source "https://rubygems.org"
gemspec

rails_version = ENV['CI_RAILS_VERSION'] || '>= 0.0'

gem 'activesupport', rails_version
gem 'activerecord', rails_version
gem 'kaminari-activerecord'
if ['~> 8.0.0', '>= 0', '>= 0.0'].include?(rails_version)
  gem 'sqlite3', '~> 2'
else
  gem 'sqlite3', '~> 1.7.3'
end
gem 'yard'
gem 'mutex_m'
gem 'bigdecimal'
gem 'base64'
