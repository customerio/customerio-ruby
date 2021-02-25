require 'net/http'
require 'multi_json'

module Customerio
  module Regions
    Region = Struct.new(:track_url, :api_url)

    US = Customerio::Regions::Region.new('https://track.customer.io', 'https://api.customer.io').freeze
    EU = Customerio::Regions::Region.new('https://track-eu.customer.io', 'https://api-eu.customer.io').freeze
  end
end
