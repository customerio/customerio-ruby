require 'net/http'
require 'multi_json'

module Customerio
  class Regions
    US = :us
    EU = :eu

    def self.track_url_for(region)
      ensure_valid(region)

      {
        us: 'https://track.customer.io',
        eu: 'https://track-eu.customer.io'
      }[region]
    end

    def self.api_url_for(region)
      ensure_valid(region)

      {
        us: 'https://api.customer.io',
        eu: 'https://api-eu.customer.io'
      }[region]
    end

    private

    def self.ensure_valid(region)
      raise "region must be one of #{US} or #{EU}" unless [EU, US].include?(region)
    end
  end
end
