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
        MultiJson.load(response.body)
      when Net::HTTPBadRequest then
        json = MultiJson.load(response.body)
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
        MultiJson.load(response.body)
      when Net::HTTPBadRequest then
        json = MultiJson.load(response.body)
        raise Customerio::InvalidResponse.new(response.code, json['meta']['error'], response)
      else
        raise InvalidResponse.new(response.code, response.body)
      end
    end

    def send_sms(req)
      raise "request must be an instance of Customerio::SendSMSRequest" unless req.is_a?(Customerio::SendSMSRequest)
      response = @client.request(:post, send_sms_path, req.message)

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

    def send_inbox_message(req)
      raise "request must be an instance of Customerio::SendInboxMessageRequest" unless req.is_a?(Customerio::SendInboxMessageRequest)
      response = @client.request(:post, send_inbox_message_path, req.message)

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

    private

    def send_email_path
      "/v1/send/email"
    end

    def send_push_path
      "/v1/send/push"
    end

    def send_sms_path
      "/v1/send/sms"
    end

    def send_inbox_message_path
      "/v1/send/inbox_message"
    end
  end
end
