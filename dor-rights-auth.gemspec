# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
  
Gem::Specification.new do |s|
  s.name        = "dor-rights-auth"
  s.version     = "1.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Willy Mene"]
  s.email       = ["wmene@stanford.edu"]
  s.summary     = "Parses rightsMetadata xml into a useable object"
  s.description = "Parses rightsMetadata xml into a useable object"
 
  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency "nokogiri"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "yard"
 
  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end
