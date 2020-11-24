require 'net/http'
require 'multi_json'

module Customerio
  DEFAULT_BASE_URI = 'https://track.customer.io'
  DEFAULT_TIMEOUT  = 10

  class BaseClient
    def initialize(auth, options = {})
      @auth = auth
      @timeout = options[:timeout] || DEFAULT_TIMEOUT

      @json = options.has_key?(:json) ? options[:json] : true
      @base_uri = options[:base_uri] || DEFAULT_BASE_URI
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
    end

    def request(method, path, body = nil, headers = {})
      execute(method, path, body, headers)
    end

    private

    def extract_attributes(args)
      hash = args.last.is_a?(Hash) ? args.pop : {}
      hash.inject({}){ |hash, (k,v)| hash[k.to_sym] = v; hash }
    end

    def execute(method, path, body = nil, headers = {})
      uri = URI.join(@base_uri, path)

      session = Net::HTTP.new(uri.host, uri.port)
      session.use_ssl = (uri.scheme == 'https')
      session.open_timeout = @timeout
      session.read_timeout = @timeout

      req = request_class(method).new(uri.path)
      req.initialize_http_header(headers)
      req.basic_auth @auth[:site_id], @auth[:secret_key]

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
