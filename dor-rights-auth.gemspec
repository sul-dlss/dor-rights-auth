# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'dor-rights-auth'
  s.version     = '1.7.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Willy Mene', 'Joe Atzberger', 'Johnathan Martin', 'Naomi Dushay']
  s.email       = ['dlss-infrastructure-team@lists.stanford.edu']
  s.summary     = 'Parses rightsMetadata xml into a useable object'
  s.description = 'Parses rightsMetadata xml into a useable object'

  s.required_rubygems_version = '>= 1.3.6'
  s.required_ruby_version = '> 2.5'

  s.add_dependency 'nokogiri'

  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'yard'

  s.files        = Dir.glob('lib/**/*')
  s.require_path = 'lib'
end
