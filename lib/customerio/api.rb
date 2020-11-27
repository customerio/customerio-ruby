require 'net/http'
require 'multi_json'

module Customerio
  class APIClient
    DEFAULT_BASE_URI = 'https://api.customer.io'

    def initialize(app_key, options = {})
      options[:base_uri] = DEFAULT_BASE_URI if options[:base_uri].nil? || options[:base_uri].empty?
      @client = Customerio::BaseClient.new({ app_key: app_key }, options)
    end

    def send_email(payload)
      @client.request_and_verify_response(:post, send_email_path, payload)
    end

    private

    def send_email_path
      "/v1/api/send/email"
    end
  end
end
