# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
  
Gem::Specification.new do |s|
  s.name        = "dor-rights-auth"
  s.version     = "0.8.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Willy Mene"]
  s.email       = ["wmene@stanford.edu"]
  s.summary     = "Parses rightsMetadata xml into a useable object"
  s.description = "Parses rightsMetadata xml into a useable object"
 
  s.required_rubygems_version = ">= 1.3.6"
  
  # All dependencies are runtime dependencies, since this gem's "runtime" is
  # the dependent gem's development-time.
  s.add_dependency "nokogiri"
  s.add_dependency "rest-client"
  
  s.add_development_dependency "rspec", "< 2.0" # We're not ready to upgrade to rspec 2
  s.add_development_dependency "ruby-debug"
 
  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end