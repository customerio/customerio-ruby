require 'net/http'
require 'multi_json'

module Customerio
  class APIClient
    def initialize(app_key, options = {})
      options[:region] = Customerio::Regions::US if options[:region].nil?
      raise "region must be an instance of Customerio::Regions::Region" unless options[:region].is_a?(Customerio::Regions::Region)

      options[:url] = options[:region].api_url if options[:url].nil? || options[:url].empty?
      @client = Customerio::BaseClient.new({ app_key: app_key }, options)
    end

    def send_email(req)
      raise "request must be an instance of Customerio::SendEmailRequest" unless req.is_a?(Customerio::SendEmailRequest)
      response = @client.request(:post, send_email_path, req.message)

      case response
      when Net::HTTPSuccess then
        JSON.parse(response.body)
      when Net::HTTPBadRequest then
        json = JSON.parse(response.body)
        raise Customerio::InvalidResponse.new(response.code, json['meta']['error'], response)
      else
        raise InvalidResponse.new(response.code, response.body)
      end
    end

    def send_push(req)
      raise "request must be an instance of Customerio::SendPushRequest" unless req.is_a?(Customerio::SendPushRequest)
      response = @client.request(:post, send_push_path, req.message)

      case response
      when Net::HTTPSuccess then
        JSON.parse(response.body)
      when Net::HTTPBadRequest then
        json = JSON.parse(response.body)
        raise Customerio::InvalidResponse.new(response.code, json['meta']['error'], response)
      else
        raise InvalidResponse.new(response.code, response.body)
      end
    end

    def trigger_broadcast(req)
      unless req.is_a?(Customerio::TriggerBroadcastRequest)
        raise 'request must be an instance of Customerio::TriggerBroadcastRequest'
      end

      response = @client.request(:post, trigger_broadcast_path(req.broadcast_id), req.payload)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPBadRequest
        json = JSON.parse(response.body)
        raise Customerio::InvalidResponse.new(response.code, json['meta']['error'], response)
      else
        raise InvalidResponse.new(response.code, response.body)
      end
    end

    private

    def send_email_path
      "/v1/send/email"
    end

    def send_push_path
      "/v1/send/push"
    end

    def trigger_broadcast_path(broadcast_id)
      "/v1/campaigns/#{broadcast_id}/triggers"
    end
  end
end
