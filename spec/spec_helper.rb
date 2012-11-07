#require 'rubygems'
#require 'bundler/setup'

require 'rspec'
require 'rbovirt'

module OVIRT::RSpec end

require "#{File.dirname(__FILE__)}/lib/endpoint"

RSpec.configure do |config|
  config.include OVIRT::RSpec::Endpoint
end