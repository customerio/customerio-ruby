require 'rubygems'
require 'bundler/setup'

require 'customerio'
require 'webmock'

WebMock.disable_net_connect!

require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
end
