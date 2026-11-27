# frozen_string_literal: true

require "json"
require "net/http"

module Customerio
  class APIClient
    def initialize(app_key, options = {})
      options = options.dup
      options[:region] = Regions::US if options[:region].nil?
      unless options[:region].is_a?(Regions::Region)
        raise ArgumentError, "region must be an instance of Customerio::Regions::Region"
      end

      options[:url] = options[:region].api_url if options[:url].nil? || options[:url].empty?
      @client = BaseClient.new({ app_key: app_key }, options)
    end

    def send_email(req)
      validate_request!(req, SendEmailRequest)

      deliver(send_email_path, req.message)
    end

    def send_push(req)
      validate_request!(req, SendPushRequest)

      deliver(send_push_path, req.message)
    end

    def send_sms(req)
      validate_request!(req, SendSMSRequest)

      deliver(send_sms_path, req.message)
    end

    def send_whatsapp(req)
      validate_request!(req, SendWhatsAppRequest)

      deliver(send_whatsapp_path, req.message)
    end

    def send_inbox_message(req)
      validate_request!(req, SendInboxMessageRequest)

      deliver(send_inbox_message_path, req.message)
    end

    def send_in_app(req)
      validate_request!(req, SendInAppRequest)

      deliver(send_in_app_path, req.message)
    end

    def trigger_broadcast(req)
      validate_request!(req, TriggerBroadcastRequest)

      deliver(trigger_broadcast_path(req.broadcast_id), req.message)
    end

    def create_import(req)
      validate_request!(req, CreateImportRequest)

      deliver(imports_path, { import: req.message })
    end

    def get_import(import_id)
      whole_number = (import_id.is_a?(Integer) || import_id.is_a?(String)) && import_id.to_s.match?(/\A\d+\z/)
      raise ArgumentError, "import_id must be a whole number" unless whole_number

      deliver(import_path(import_id), nil, :get)
    end

    private

    def deliver(path, message, method = :post)
      response = @client.request(method, path, message)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPBadRequest
        error = JSON.parse(response.body).dig("meta", "error")
        raise InvalidResponse.new(response.code, error, response)
      else
        raise InvalidResponse.new(response.code, response.body, response)
      end
    end

    def validate_request!(request, request_class)
      return if request.is_a?(request_class)

      raise ArgumentError, "request must be an instance of #{request_class}"
    end

    def send_email_path
      "/v1/send/email"
    end

    def send_push_path
      "/v1/send/push"
    end

    def send_sms_path
      "/v1/send/sms"
    end

    def send_whatsapp_path
      "/v1/send/whatsapp"
    end

    def send_inbox_message_path
      "/v1/send/inbox_message"
    end

    def send_in_app_path
      "/v1/send/in_app"
    end

    def trigger_broadcast_path(broadcast_id)
      "/v1/campaigns/#{broadcast_id}/triggers"
    end

    def imports_path
      "/v1/imports"
    end

    def import_path(import_id)
      "/v1/imports/#{import_id}"
    end
  end
end
