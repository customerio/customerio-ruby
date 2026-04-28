require "addressable/uri"

module Customerio
  class IdentifierType
    ID = "id"
    EMAIL = "email"
    CIOID = "cio_id"
  end

  class Client
    DELIVERY_OPENED = 'opened'
    DELIVERY_CONVERTED = 'converted'
    DELIVERY_DELIVERED = 'delivered'
    DELIVERY_BOUNCED = 'bounced'
    DELIVERY_CLICKED = 'clicked'
    DELIVERY_DEFERRED = 'deferred'
    DELIVERY_DROPPED = 'dropped'
    DELIVERY_SPAMMED = 'spammed'

    VALID_PUSH_EVENTS = [DELIVERY_OPENED, DELIVERY_CONVERTED, DELIVERY_DELIVERED]

    # The valid delivery events depend on the channel
    # However, there is no way to validate the channel prior the API request
    # https://customer.io/docs/api/track/#operation/metrics
    VALID_DELIVERY_METRICS = VALID_PUSH_EVENTS + [DELIVERY_BOUNCED, DELIVERY_CLICKED, DELIVERY_DEFERRED, DELIVERY_DROPPED, DELIVERY_SPAMMED]

    class MissingIdAttributeError < RuntimeError; end
    class ParamError < RuntimeError; end

    def initialize(site_id, api_key, options = {})
      options[:region] = Customerio::Regions::US if options[:region].nil?
      raise "region must be an instance of Customerio::Regions::Region" unless options[:region].is_a?(Customerio::Regions::Region)

      options[:url] = options[:region].track_url if options[:url].nil? || options[:url].empty?
      @client = Customerio::BaseClient.new({ site_id: site_id, api_key: api_key }, options)
    end

    def identify(attributes)
      create_or_update(attributes)
    end

    def delete(customer_id)
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      @client.request_and_verify_response(:delete, customer_path(customer_id))
    end

    def suppress(customer_id)
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      @client.request_and_verify_response(:post, suppress_path(customer_id))
    end

    def unsuppress(customer_id)
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      @client.request_and_verify_response(:post, unsuppress_path(customer_id))
    end

    def track(customer_id, event_name, attributes = {})
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      raise ParamError.new("event_name must be a non-empty string") if is_empty?(event_name)

      create_customer_event(customer_id, event_name, attributes)
    end

    def pageview(customer_id, page, attributes = {})
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      raise ParamError.new("page must be a non-empty string") if is_empty?(page)

      create_pageview_event(customer_id, page, attributes)
    end

    def track_anonymous(anonymous_id, event_name, attributes = {})
      raise ParamError.new("event_name must be a non-empty string") if is_empty?(event_name)

      create_anonymous_event(anonymous_id, event_name, attributes)
    end

    def add_device(customer_id, device_id, platform, data={})
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      raise ParamError.new("device_id must be a non-empty string") if is_empty?(device_id)
      raise ParamError.new("platform must be a non-empty string") if is_empty?(platform)

      if data.nil?
        data = {}
      end

      raise ParamError.new("data parameter must be a hash") unless data.is_a?(Hash)

      @client.request_and_verify_response(:put, device_path(customer_id), {
        :device => data.update({
          :id => device_id,
          :platform => platform,
        })
      })
    end

    def delete_device(customer_id, device_id)
      raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
      raise ParamError.new("device_id must be a non-empty string") if is_empty?(device_id)

      @client.request_and_verify_response(:delete, device_id_path(customer_id, device_id))
    end

    # Customer.io deprecated per https://customer.io/docs/api/track/#operation/pushMetrics
    def track_push_notification_event(event_name, attributes = {})
        keys = [:delivery_id, :device_id, :timestamp]
        attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }].
            select { |k, v| keys.include?(k) }

        raise ParamError.new('event_name must be one of opened, converted, or delivered') unless VALID_PUSH_EVENTS.include?(event_name)
        raise ParamError.new('delivery_id must be a non-empty string') unless attributes[:delivery_id] != "" and !attributes[:delivery_id].nil?
        raise ParamError.new('device_id must be a non-empty string') unless attributes[:device_id] != "" and !attributes[:device_id].nil?
        raise ParamError.new('timestamp must be a valid timestamp') unless valid_timestamp?(attributes[:timestamp])

        @client.request_and_verify_response(:post, track_push_notification_event_path, attributes.merge(event: event_name))
    end

    def track_delivery_metric(metric_name, attributes = {})
      keys = [:delivery_id, :timestamp, :recipient, :reason, :href]
      attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }].
        select { |k, v| keys.include?(k) }

      raise ParamError.new('metric_name must be one of bounced, clicked, converted, deferred, delivered, dropped, opened, and spammed') unless VALID_DELIVERY_METRICS.include?(metric_name)
      raise ParamError.new('delivery_id must be a non-empty string') unless attributes[:delivery_id] != "" and !attributes[:delivery_id].nil?
      raise ParamError.new('timestamp must be a valid timestamp') if attributes[:timestamp] && !valid_timestamp?(attributes[:timestamp])
      raise ParamError.new('href must be a valid url') if attributes[:href] && !valid_url?(attributes[:href].present?)

      @client.request_and_verify_response(:post, track_delivery_metric_path, attributes.merge(metric: metric_name))
    end

    def merge_customers(primary_id_type, primary_id, secondary_id_type, secondary_id)
      raise ParamError.new("invalid primary_id_type") if !is_valid_id_type?(primary_id_type)
      raise ParamError.new("primary_id must be a non-empty string") if is_empty?(primary_id)
      raise ParamError.new("invalid secondary_id_type") if !is_valid_id_type?(secondary_id_type)
      raise ParamError.new("secondary_id must be a non-empty string") if is_empty?(secondary_id)

      body = { :primary => {primary_id_type => primary_id}, :secondary => {secondary_id_type => secondary_id} }

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

    def track_delivery_metric_path
      "/api/v1/metrics"
    end

    def merge_customers_path
      "/api/v1/merge_customers"
    end

    def create_or_update(attributes = {})
      attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }]
      if is_empty?(attributes[:id]) && is_empty?(attributes[:cio_id]) && is_empty?(attributes[:customer_id])
        raise MissingIdAttributeError.new("Must provide a customer id")
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
      if !is_empty?(attributes[:cio_id])
        customer_id = "cio_" + attributes[:cio_id]
      end
      if !is_empty?(attributes[:customer_id])
        customer_id = attributes[:customer_id]
      end
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
      body = { :name => event_name, :data => attributes }
      body[:timestamp] = attributes[:timestamp] if valid_timestamp?(attributes[:timestamp])
      body[:anonymous_id] = anonymous_id unless is_empty?(anonymous_id)
      body[:type] = event_type unless is_empty?(event_type)

      @client.request_and_verify_response(:post, url, body)
    end

    def valid_timestamp?(timestamp)
      timestamp && timestamp.is_a?(Integer) && timestamp > 999999999 && timestamp < 100000000000
    end

    def valid_url?(url)
      %w[http https].include?(Addressable::URI.parse(url)&.scheme)
    rescue Addressable::URI::InvalidURIError
      false
    end

    def is_empty?(val)
      val.nil? || (val.is_a?(String) && val.strip == "")
    end

    def is_valid_id_type?(input)
      [IdentifierType::ID, IdentifierType::CIOID, IdentifierType::EMAIL].include? input
    end
  end
end
