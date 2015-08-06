require 'rubygems'
require 'bundler/setup'

require 'customerio'
require 'fakeweb'

FakeWeb.allow_net_connect = false

require 'rspec'
RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
end
