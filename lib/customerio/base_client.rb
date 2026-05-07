# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Customerio
  DEFAULT_TIMEOUT = 10

  class InvalidRequest < StandardError; end

  class InvalidResponse < StandardError
    attr_reader :code, :response

    def initialize(code, body, response = nil)
      @code = code
      @response = response

      super(body)
    end
  end

  class BaseClient
    def initialize(auth, options = {})
      @auth = auth
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
      @base_uri = options[:url]
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
      request_headers = headers.dup

      session = Net::HTTP.new(uri.host, uri.port)
      session.use_ssl = uri.scheme == "https"
      session.open_timeout = @timeout
      session.read_timeout = @timeout

      req = request_class(method).new(uri.request_uri)

      request_headers["User-Agent"] = "Customer.io Ruby Client/#{VERSION}"

      if @auth.key?(:site_id) && @auth.key?(:api_key)
        req.initialize_http_header(request_headers)
        req.basic_auth @auth[:site_id], @auth[:api_key]
      else
        request_headers["Authorization"] = "Bearer #{@auth[:app_key]}"
        req.initialize_http_header(request_headers)
      end

      unless body.nil?
        req.add_field("Content-Type", "application/json")
        req.body = JSON.generate(body)
      end

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
      when :get
        Net::HTTP::Get
      else
        raise InvalidRequest, "Invalid request method #{method.inspect}"
      end
    end

    def verify_response(response)
      case response
      when Net::HTTPSuccess
        response
      else
        raise InvalidResponse.new(response.code, response.body, response)
      end
    end
  end
end
