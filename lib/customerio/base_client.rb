require 'net/http'
require 'multi_json'

module Customerio
  DEFAULT_TIMEOUT  = 10

  class BaseClient
    class InvalidRequest < RuntimeError; end
    class InvalidResponse < RuntimeError
      attr_reader :response

      def initialize(message, response)
        super(message)
        @response = response
      end
    end

    def initialize(auth, options = {})
      @auth = auth
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
      @json = options.has_key?(:json) ? options[:json] : true
      @base_uri = options[:base_uri]
    end

    def request(method, path, body = nil, headers = {})
      execute(method, path, body, headers)
    end

    def request_and_verify_response(method, path, body = nil, headers = {})
      verify_response(request(method, path, body, headers))
    end

    private

    def execute(method, path, body = nil, headers = {})
      uri = URI.join(@base_uri, path)

      session = Net::HTTP.new(uri.host, uri.port)
      session.use_ssl = (uri.scheme == 'https')
      session.open_timeout = @timeout
      session.read_timeout = @timeout

      req = request_class(method).new(uri.path)

      if @auth.has_key?(:site_id) && @auth.has_key?(:secret_key)
        req.initialize_http_header(headers)
        req.basic_auth @auth[:site_id], @auth[:secret_key]
      else
        headers['Authorization'] = "Bearer #{@auth[:app_key]}"
        req.initialize_http_header(headers)
      end

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

    def verify_response(response)
      if response.code.to_i >= 200 && response.code.to_i < 300
        response
      else
        raise InvalidResponse.new("Customer.io API returned an invalid response: #{response.code}", response)
      end
    end
  end
end
