require 'rubygems'
require 'bundler/setup'

require 'customerio'
require 'fakeweb'

FakeWeb.allow_net_connect = false

RSpec.configure do |config|
  config.after(:each) do
    Customerio.configuration = nil
  end
end
