# frozen_string_literal: true

require "addressable/uri"

module Customerio
  class IdentifierType
    ID = "id"
    EMAIL = "email"
    CIOID = "cio_id"
  end

  class Client
    PUSH_OPENED = "opened"
    PUSH_CONVERTED = "converted"
    PUSH_DELIVERED = "delivered"

    VALID_PUSH_EVENTS = [PUSH_OPENED, PUSH_CONVERTED, PUSH_DELIVERED].freeze

    class MissingIdAttributeError < StandardError; end
    class ParamError < StandardError; end

    def initialize(site_id, api_key, options = {})
      options = options.dup
      options[:region] = Regions::US if options[:region].nil?
      unless options[:region].is_a?(Regions::Region)
        raise ArgumentError, "region must be an instance of Customerio::Regions::Region"
      end

      options[:url] = options[:region].track_url if options[:url].nil? || options[:url].empty?
      @client = BaseClient.new({ site_id: site_id, api_key: api_key }, options)
    end

    def identify(attributes)
      create_or_update(attributes)
    end

    def delete(customer_id)
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)

      @client.request_and_verify_response(:delete, customer_path(customer_id))
    end

    def suppress(customer_id)
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)

      @client.request_and_verify_response(:post, suppress_path(customer_id))
    end

    def unsuppress(customer_id)
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)

      @client.request_and_verify_response(:post, unsuppress_path(customer_id))
    end

    def track(customer_id, event_name, attributes = {})
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)
      raise ParamError, "event_name must be a non-empty string" if empty?(event_name)

      create_customer_event(customer_id, event_name, attributes)
    end

    def pageview(customer_id, page, attributes = {})
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)
      raise ParamError, "page must be a non-empty string" if empty?(page)

      create_pageview_event(customer_id, page, attributes)
    end

    def track_anonymous(anonymous_id, event_name, attributes = {})
      raise ParamError, "event_name must be a non-empty string" if empty?(event_name)

      create_anonymous_event(anonymous_id, event_name, attributes)
    end

    def add_device(customer_id, device_id, platform, data = {})
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)
      raise ParamError, "device_id must be a non-empty string" if empty?(device_id)
      raise ParamError, "platform must be a non-empty string" if empty?(platform)

      data = {} if data.nil?

      raise ParamError, "data parameter must be a hash" unless data.is_a?(Hash)

      @client.request_and_verify_response(
        :put,
        device_path(customer_id),
        device: data.merge(id: device_id, platform: platform)
      )
    end

    def delete_device(customer_id, device_id)
      raise ParamError, "customer_id must be a non-empty string" if empty?(customer_id)
      raise ParamError, "device_id must be a non-empty string" if empty?(device_id)

      @client.request_and_verify_response(:delete, device_id_path(customer_id, device_id))
    end

    def track_push_notification_event(event_name, attributes = {})
      keys = %i[delivery_id device_id timestamp]
      attributes = symbolize_keys(attributes).slice(*keys)

      unless VALID_PUSH_EVENTS.include?(event_name)
        raise ParamError, "event_name must be one of opened, converted, or delivered"
      end

      raise ParamError, "delivery_id must be a non-empty string" if empty?(attributes[:delivery_id])
      raise ParamError, "device_id must be a non-empty string" if empty?(attributes[:device_id])
      raise ParamError, "timestamp must be a valid timestamp" unless valid_timestamp?(attributes[:timestamp])

      @client.request_and_verify_response(
        :post,
        track_push_notification_event_path,
        attributes.merge(event: event_name)
      )
    end

    def merge_customers(primary_id_type, primary_id, secondary_id_type, secondary_id)
      raise ParamError, "invalid primary_id_type" unless valid_id_type?(primary_id_type)
      raise ParamError, "primary_id must be a non-empty string" if empty?(primary_id)
      raise ParamError, "invalid secondary_id_type" unless valid_id_type?(secondary_id_type)
      raise ParamError, "secondary_id must be a non-empty string" if empty?(secondary_id)

      body = { primary: { primary_id_type => primary_id }, secondary: { secondary_id_type => secondary_id } }

      @client.request_and_verify_response(:post, merge_customers_path, body)
    end

    private

    def escape(val)
      # CGI.escape is recommended for escaping, however, it doesn't correctly escape spaces.
      Addressable::URI.encode_component(val.to_s, Addressable::URI::CharacterClasses::UNRESERVED)
    end

    def device_path(customer_id)
      "/api/v1/customers/#{escape(customer_id)}/devices"
    end

    def device_id_path(customer_id, device_id)
      "/api/v1/customers/#{escape(customer_id)}/devices/#{escape(device_id)}"
    end

    def customer_path(id)
      "/api/v1/customers/#{escape(id)}"
    end

    def suppress_path(customer_id)
      "/api/v1/customers/#{escape(customer_id)}/suppress"
    end

    def unsuppress_path(customer_id)
      "/api/v1/customers/#{escape(customer_id)}/unsuppress"
    end

    def track_push_notification_event_path
      "/push/events"
    end

    def merge_customers_path
      "/api/v1/merge_customers"
    end

    def create_or_update(attributes = {})
      attributes = symbolize_keys(attributes)
      if empty?(attributes[:id]) && empty?(attributes[:cio_id]) && empty?(attributes[:customer_id])
        raise MissingIdAttributeError, "Must provide a customer id"
      end

      # Use cio_id as the identifier, if present,
      # to allow the id and email identifiers to be updated.
      # The person is identified by a customer ID, which is included
      # in the path to the Track v1 API. Choose the ID in this order
      # from highest to lowest precedence:
      #
      # 1. customer_id: "id", an email address, or "cio_id" value.
      #    Any "cio_id" values need to be prefixed "cio_"
      #    so that the Track v1 API knows it's a cio_id.
      #
      # 2. cio_id: The cio_id value (no prefix required).
      #
      # 3. id: The id value.
      customer_id = attributes[:id]
      customer_id = "cio_#{attributes[:cio_id]}" unless empty?(attributes[:cio_id])
      customer_id = attributes[:customer_id] unless empty?(attributes[:customer_id])

      # customer_id is not an attribute, so remove it.
      attributes.delete(:customer_id)

      url = customer_path(customer_id)
      @client.request_and_verify_response(:put, url, attributes)
    end

    def create_customer_event(customer_id, event_name, attributes = {})
      create_event(
        url: "#{customer_path(customer_id)}/events",
        event_name: event_name,
        attributes: attributes
      )
    end

    def create_anonymous_event(anonymous_id, event_name, attributes = {})
      create_event(
        url: "/api/v1/events",
        event_name: event_name,
        anonymous_id: anonymous_id,
        attributes: attributes
      )
    end

    def create_pageview_event(customer_id, page, attributes = {})
      create_event(
        url: "#{customer_path(customer_id)}/events",
        event_type: "page",
        event_name: page,
        attributes: attributes
      )
    end

    def create_event(url:, event_name:, anonymous_id: nil, event_type: nil, attributes: {})
      body = { name: event_name, data: attributes }
      body[:timestamp] = attributes[:timestamp] if valid_timestamp?(attributes[:timestamp])
      body[:anonymous_id] = anonymous_id unless empty?(anonymous_id)
      body[:type] = event_type unless empty?(event_type)

      @client.request_and_verify_response(:post, url, body)
    end

    def valid_timestamp?(timestamp)
      timestamp.is_a?(Integer) && timestamp > 999_999_999 && timestamp < 100_000_000_000
    end

    def empty?(val)
      val.nil? || (val.is_a?(String) && val.strip.empty?)
    end

    def valid_id_type?(input)
      [IdentifierType::ID, IdentifierType::CIOID, IdentifierType::EMAIL].include? input
    end

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
