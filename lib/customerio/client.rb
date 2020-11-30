require 'cgi'

module Customerio
  class Client
    DEFAULT_TRACK_URL = 'https://track.customer.io'

    class MissingIdAttributeError < RuntimeError; end
    class ParamError < RuntimeError; end

    def initialize(site_id, api_key, options = {})
      options[:url] = DEFAULT_TRACK_URL if options[:url].nil? || options[:url].empty?
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

    def track(*args)
      attributes = extract_attributes(args)

      if args.length == 1
        # Only passed in an event name, create an anonymous event
        event_name = args.first
        raise ParamError.new("event_name must be a non-empty string") if is_empty?(event_name)
        create_anonymous_event(event_name, attributes)
      else
        # Passed in a customer id and an event name.
        # Track the event for the given customer
        customer_id, event_name = args

        raise ParamError.new("customer_id must be a non-empty string") if is_empty?(customer_id)
        raise ParamError.new("event_name must be a non-empty string") if is_empty?(event_name)

        create_customer_event(customer_id, event_name, attributes)
      end
    end

    def anonymous_track(event_name, attributes = {})
      raise ParamError.new("event_name must be a non-empty string") if is_empty?(event_name)
      create_anonymous_event(event_name, attributes)
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

    def add_to_segment(segment_id, customer_ids)
      raise ParamError.new("segment_id must be an integer") unless segment_id.is_a? Integer
      raise ParamError.new("customer_ids must be a list of values") unless customer_ids.is_a? Array

      customer_ids = customer_ids.map{ |id| id.to_s }

      @client.request_and_verify_response(:post, add_to_segment_path(segment_id), {
        :ids => customer_ids,
      })
    end

    def remove_from_segment(segment_id, customer_ids)
      raise ParamError.new("segment_id must be an integer") unless segment_id.is_a? Integer
      raise ParamError.new("customer_ids must be a list of values") unless customer_ids.is_a? Array

      customer_ids = customer_ids.map{ |id| id.to_s }
      
      @client.request_and_verify_response(:post, remove_from_segment_path(segment_id), {
        :ids => customer_ids,
      })
    end

    private

    def escape(val)
      # CGI.escape is recommended for escaping, however, it doesn't correctly escape spaces.
      Addressable::URI.encode_component(val.to_s, Addressable::URI::CharacterClasses::UNRESERVED)
    end

    def add_to_segment_path(segment_id)
      "/api/v1/segments/#{escape(segment_id)}/add_customers"
    end

    def remove_from_segment_path(segment_id)
      "/api/v1/segments/#{escape(segment_id)}/remove_customers"
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

    def create_or_update(attributes = {})
      attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }]
      raise MissingIdAttributeError.new("Must provide a customer id") unless attributes[:id]

      url = customer_path(attributes[:id])
      @client.request_and_verify_response(:put, url, attributes)
    end

    def create_customer_event(customer_id, event_name, attributes = {})
      create_event("#{customer_path(customer_id)}/events", event_name, attributes)
    end

    def create_anonymous_event(event_name, attributes = {})
      create_event("/api/v1/events", event_name, attributes)
    end

    def create_event(url, event_name, attributes = {})
      body = { :name => event_name, :data => attributes }
      body[:timestamp] = attributes[:timestamp] if valid_timestamp?(attributes[:timestamp])
      @client.request_and_verify_response(:post, url, body)
    end

    def valid_timestamp?(timestamp)
      timestamp && timestamp.is_a?(Integer) && timestamp > 999999999 && timestamp < 100000000000
    end

    def extract_attributes(args)
      hash = args.last.is_a?(Hash) ? args.pop : {}
      hash.inject({}){ |hash, (k,v)| hash[k.to_sym] = v; hash }
    end

    def is_empty?(val)
      val.nil? || (val.is_a?(String) && val.strip == "")
    end
  end
end
