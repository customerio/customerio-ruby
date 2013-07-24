require 'httparty'

module Customerio
  class Client
    include HTTParty
    base_uri 'https://track.customer.io'

    class MissingIdAttributeError < RuntimeError; end
    class InvalidResponse < RuntimeError; end

    def initialize(site_id, secret_key)
      @auth = { :username => site_id, :password => secret_key }
    end

    def identify(attributes)
      create_or_update(attributes)
    end

    def delete(customer_id)
      verify_response(self.class.delete(customer_path(customer_id), options))
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

    private

    def create_or_update(attributes = {})
      raise MissingIdAttributeError.new("Must provide a customer id") unless attributes[:id]
      attributes = normalize_attributes(attributes)

      url = customer_path(attributes[:id])

      verify_response(self.class.put(url, options.merge(:body => attributes)))
    end

    def create_customer_event(customer_id, event_name, attributes = {})
      create_event("#{customer_path(customer_id)}/events", event_name, attributes)
    end

    def create_anonymous_event(event_name, attributes = {})
      create_event("/api/v1/events", event_name, attributes)
    end

    def create_event(url, event_name, attributes = {})
      attributes = normalize_attributes(attributes)
      body = { :name => event_name, :data => attributes }
      body[:timestamp] = attributes[:timestamp] if valid_timestamp?(attributes[:timestamp])
      verify_response(self.class.post(url, options.merge(:body => body)))
    end

    def customer_path(id)
      "/api/v1/customers/#{id}"
    end

    def valid_timestamp?(timestamp)
      timestamp && timestamp.is_a?(Integer) && timestamp > 999999999 && timestamp < 100000000000
    end

    def verify_response(response)
      if response.code >= 200 && response.code < 300
        response
      else
        raise InvalidResponse.new("Customer.io API returned an invalid response: #{response.code}")
      end
    end

    def extract_attributes(args)
      args.last.is_a?(Hash) ? args.pop : {}
    end

    def normalize_attributes(attributes)
      attributes.inject({}){ |result, (k,v)| result[k.to_sym] = encode_value(v); result }
    end

    def encode_value(value)
      case value
      when Time, Date, DateTime
        value.to_time.to_i
      else
        value
      end
    end

    def options
      { :basic_auth => @auth }
    end
  end
end
