require 'rubygems'
require 'bundler/setup'

require 'customerio'
require 'fakeweb'

FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.before(:each) do
    Customerio::Client.default_config
  end
end
