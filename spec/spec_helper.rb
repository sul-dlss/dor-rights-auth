# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'

require 'coveralls'
Coveralls.wear!
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  Coveralls::SimpleCov::Formatter
]

require 'byebug'
require 'dor/rights_auth'
