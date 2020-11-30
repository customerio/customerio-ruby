require 'net/http'
require 'multi_json'

module Customerio
  class APIClient
    DEFAULT_API_URL = 'https://api.customer.io'

    def initialize(app_key, options = {})
      options[:url] = DEFAULT_API_URL if options[:url].nil? || options[:url].empty?
      @client = Customerio::BaseClient.new({ app_key: app_key }, options)
    end

    def send_email(payload)
      @client.request_and_verify_response(:post, send_email_path, payload)
    end

    private

    def send_email_path
      "/v1/send/email"
    end
  end
end
