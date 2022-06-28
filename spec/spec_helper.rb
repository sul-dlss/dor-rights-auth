# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'bundler/setup'
require 'rspec'
require 'dor/rights_auth'
