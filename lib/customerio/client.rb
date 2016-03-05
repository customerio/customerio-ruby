require 'net/http'
require 'multi_json'

module Customerio
  DEFAULT_BASE_URI = 'https://track.customer.io'
  DEFAULT_TIMEOUT  = 10

  class Client
    class MissingIdAttributeError < RuntimeError; end
    class InvalidRequest < RuntimeError; end
    class InvalidResponse < RuntimeError
      attr_reader :response

      def initialize(message, response)
        @message = message
        @response = response
      end
    end

    def initialize(site_id, secret_key, options = {})
      @username = site_id
      @password = secret_key
      @json = options.has_key?(:json) ? options[:json] : true
      @base_uri = options[:base_uri] || DEFAULT_BASE_URI
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
    end

    def identify(attributes)
      create_or_update(attributes)
    end

    def delete(customer_id)
      verify_response(request(:delete, customer_path(customer_id)))
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

    private

    def create_or_update(attributes = {})
      attributes = Hash[attributes.map { |(k,v)| [ k.to_sym, v ] }]

      raise MissingIdAttributeError.new("Must provide a customer id") unless attributes[:id]

      url = customer_path(attributes[:id])

      verify_response(request(:put, url, attributes))
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
      verify_response(request(:post, url, body))
    end

    def customer_path(id)
      "/api/v1/customers/#{id}"
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

    def request(method, path, body = nil, headers = {})
      uri = URI.join(@base_uri, path)

      session = Net::HTTP.new(uri.host, uri.port)
      session.use_ssl = (uri.scheme == 'https')
      session.open_timeout = @timeout
      session.read_timeout = @timeout

      req = request_class(method).new(uri.path)
      req.initialize_http_header(headers)
      req.basic_auth @username, @password

      add_request_body(req, body) unless body.nil?

      session.start do |http|
        http.request(req)
      end
    end

    def request_class(method)
      case method
      when :post
        Net::HTTP::Post
      when :put
        Net::HTTP::Put
      when :delete
        Net::HTTP::Delete
      else
        raise InvalidRequest.new("Invalid request method #{method.inspect}")
      end
    end

    def add_request_body(req, body)
      if @json
        req.add_field('Content-Type', 'application/json')
        req.body = MultiJson.dump(body)
      else
        req.add_field('Content-Type', 'application/x-www-form-urlencoded')
        req.body = ParamEncoder.to_params(body)
      end
    end
  end
end
