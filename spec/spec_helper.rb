$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'coveralls'
Coveralls.wear!
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  CodeClimate::TestReporter::Formatter,
  Coveralls::SimpleCov::Formatter
]

require 'dor/rights_auth'
