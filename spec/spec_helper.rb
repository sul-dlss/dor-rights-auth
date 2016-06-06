require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'

require 'coveralls'
Coveralls.wear!

require 'dor/rights_auth'
