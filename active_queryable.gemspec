# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'active_queryable/version'

Gem::Specification.new do |s|
  s.name        = 'active_queryable'
  s.version     = ActiveQueryable::VERSION
  s.date        = '2019-12-16'
  s.summary     = "Gem to make easier model's filtering and pagination"
  s.description = 'testtest'
  s.authors     = ['Mònade']
  s.email       = 'team@monade.io'
  s.files = Dir['lib/**/*']
  s.test_files = Dir['spec/**/*']
  s.required_ruby_version = '>= 1.9.3'
  s.homepage    = 'https://rubygems.org/gems/active_queryable'
  s.license     = 'MIT'
  s.add_dependency 'activesupport', ['~> 5', '< 7']
	s.add_development_dependency 'rspec', '~> 3'
	s.add_dependency 'activerecord', ['~> 5', '< 7']

end
