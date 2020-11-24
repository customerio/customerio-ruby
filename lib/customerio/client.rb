module Customerio
  class Client
    class MissingIdAttributeError < RuntimeError; end
    class ParamError < RuntimeError; end
    class InvalidRequest < RuntimeError; end
    class InvalidResponse < RuntimeError
      attr_reader :response

      def initialize(message, response)
        super(message)
        @response = response
      end
    end

    def initialize(site_id, secret_key, options = {})
      @client = Customerio::BaseClient.new({ site_id: site_id, secret_key: secret_key }, options)
    end

    def identify(attributes)
      create_or_update(attributes)
    end

    def delete(customer_id)
      verify_response(@client.request(:delete, customer_path(customer_id)))
    end

    def suppress(customer_id)
      verify_response(@client.request(:post, suppress_path(customer_id)))
    end

    def unsuppress(customer_id)
      verify_response(@client.request(:post, unsuppress_path(customer_id)))
    end

    def track(*args)
      attributes = extract_attributes(args)

      if args.length == 1
        # Only passed in an event name, create an anonymous event
        event_name = args.first
        create_anonymous_event(event_name, attributes)
      else
        # Passed in a customer id and an event name.
        # Track the event for the given customer
        customer_id, event_name = args

        create_customer_event(customer_id, event_name, attributes)
      end
    end

    def anonymous_track(event_name, attributes = {})
      create_anonymous_event(event_name, attributes)
    end

    def add_device(customer_id, device_id, platform, data={})
      raise ParamError.new("customer_id must be a non-empty string") unless customer_id != "" and !customer_id.nil?
      raise ParamError.new("device_id must be a non-empty string") unless device_id != "" and !device_id.nil?
      raise ParamError.new("platform must be a non-empty string") unless platform != "" and !platform.nil?

      if data.nil?
        data = {}
      end

      raise ParamError.new("data parameter must be a hash") unless data.is_a?(Hash)

      verify_response(@client.request(:put, device_path(customer_id), {
        :device => data.update({
          :id => device_id,
          :platform => platform,
        })
      }))
    end

    def delete_device(customer_id, device_id)
      raise ParamError.new("customer_id must be a non-empty string") unless customer_id != "" and !customer_id.nil?
      raise ParamError.new("device_id must be a non-empty string") unless device_id != "" and !device_id.nil?
      
      verify_response(@client.request(:delete, device_id_path(customer_id, device_id)))
    end

    def add_to_segment(segment_id, customer_ids)
      raise ParamError.new("segment_id must be an integer") unless segment_id.is_a? Integer
      raise ParamError.new("customer_ids must be a list of values") unless customer_ids.is_a? Array

      customer_ids = customer_ids.map{ |id| id.to_s }

      verify_response(@client.request(:post, add_to_segment_path(segment_id), {
        :ids => customer_ids,
      }))
    end

    def remove_from_segment(segment_id, customer_ids)
      raise ParamError.new("segment_id must be an integer") unless segment_id.is_a? Integer
      raise ParamError.new("customer_ids must be a list of values") unless customer_ids.is_a? Array

      customer_ids = customer_ids.map{ |id| id.to_s }
      
      verify_response(@client.request(:post, remove_from_segment_path(segment_id), {
        :ids => customer_ids,
      }))
    end

    private

    def add_to_segment_path(segment_id)
      "/api/v1/segments/#{segment_id}/add_customers"
    end

    def remove_from_segment_path(segment_id)
      "/api/v1/segments/#{segment_id}/remove_customers"
    end

    def device_path(customer_id)
      "/api/v1/customers/#{customer_id}/devices"
    end

    def device_id_path(customer_id, device_id)
      "/api/v1/customers/#{customer_id}/devices/#{device_id}"
    end

    def create_or_update(attributes = {})
      attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }]
      raise MissingIdAttributeError.new("Must provide a customer id") unless attributes[:id]

      url = customer_path(attributes[:id])
      verify_response(@client.request(:put, url, attributes))
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
      verify_response(@client.request(:post, url, body))
    end

    def customer_path(id)
      "/api/v1/customers/#{id}"
    end

    def suppress_path(customer_id)
      "/api/v1/customers/#{customer_id}/suppress"
    end

    def unsuppress_path(customer_id)
      "/api/v1/customers/#{customer_id}/unsuppress"
    end

    def valid_timestamp?(timestamp)
      timestamp && timestamp.is_a?(Integer) && timestamp > 999999999 && timestamp < 100000000000
    end

    def verify_response(response)
      if response.code.to_i >= 200 && response.code.to_i < 300
        response
      else
        raise InvalidResponse.new("Customer.io API returned an invalid response: #{response.code}", response)
      end
    end

    def extract_attributes(args)
      hash = args.last.is_a?(Hash) ? args.pop : {}
      hash.inject({}){ |hash, (k,v)| hash[k.to_sym] = v; hash }
    end
  end
end
