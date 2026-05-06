# frozen_string_literal: true

module Customerio
  module Regions
    Region = Struct.new(:track_url, :api_url)

    US = Region.new("https://track.customer.io", "https://api.customer.io").freeze
    EU = Region.new("https://track-eu.customer.io", "https://api-eu.customer.io").freeze
  end
end
