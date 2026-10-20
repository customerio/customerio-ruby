# frozen_string_literal: true

module Customerio
  # Raised by UnifiedClient when its key can't do what a method asks.
  #
  # Raised before the request when the key's type rules it out (a public `pk_`
  # key can't send transactional messages or trigger broadcasts). Otherwise
  # the server's 401 or 403 is re-raised as this error, with the original
  # InvalidResponse as `cause`.
  class KeyCapabilityError < StandardError
    # What the key can't do: :track, :transactional or :broadcast.
    attr_reader :capability
    # The HTTP status code as an Integer, when the server refused the key.
    attr_reader :code

    def initialize(capability, message, code = nil)
      @capability = capability
      @code = code

      super(message)
    end
  end

  # One client for tracking and transactional messages, authenticated with a
  # single key sent as a Bearer token.
  #
  # Tracking methods go to the Track API; send methods go to the App API. For
  # `pk_` / `sk_` keys the region comes from the key, and Regions::US or
  # Regions::EU disagreeing with it raises ArgumentError; a custom Region is
  # used as given. Legacy keys take any `region` and default to Regions::US.
  #
  # Every URL must be https, since the key is sent as a Bearer token.
  #
  # Other Track and App API methods are on #track_client and #api_client.
  class UnifiedClient
    # Keys in the shared format look like `{type}_{us|eu}_{random}_{checksum}`,
    # where type is `pk` (public) or `sk` (secret). The server checks the
    # checksum; the client only reads the prefix.
    KEY_PREFIX = /\A(pk|sk)_(us|eu)_/

    CAPABILITY_ACTIONS = {
      track: "send tracking data",
      transactional: "send transactional messages",
      broadcast: "trigger broadcasts"
    }.freeze

    KEY_REGIONS = { "us" => Regions::US, "eu" => Regions::EU }.freeze
    private_constant :KEY_REGIONS

    attr_reader :track_client, :region

    def initialize(api_key, options = {})
      api_key = api_key.to_s.strip
      raise ArgumentError, "api_key is required" if api_key.empty?

      match = KEY_PREFIX.match(api_key)
      @key_kind = match ? match[1].to_sym : :legacy
      @region = resolve_region(match && match[2], options[:region])
      check_urls(options)

      @track_client = BearerTrackClient.new(api_key, track_options(options))
      @api_client = APIClient.new(api_key, api_options(options))
    end

    # The App API client. Raises KeyCapabilityError for a public `pk_` key.
    def api_client
      refuse_public_key(:transactional)
      @api_client
    end

    def identify(attributes)
      guard(:track) { track_client.identify(attributes) }
    end

    def track(customer_id, event_name, attributes = {}, id: nil, timestamp: nil)
      guard(:track) { track_client.track(customer_id, event_name, attributes, id: id, timestamp: timestamp) }
    end

    def track_anonymous(anonymous_id, event_name, attributes = {}, id: nil, timestamp: nil)
      guard(:track) { track_client.track_anonymous(anonymous_id, event_name, attributes, id: id, timestamp: timestamp) }
    end

    def pageview(customer_id, page, attributes = {})
      guard(:track) { track_client.pageview(customer_id, page, attributes) }
    end

    def send_email(req)
      guard(:transactional) { api_client.send_email(req) }
    end

    def send_push(req)
      guard(:transactional) { api_client.send_push(req) }
    end

    def send_sms(req)
      guard(:transactional) { api_client.send_sms(req) }
    end

    def send_whatsapp(req)
      guard(:transactional) { api_client.send_whatsapp(req) }
    end

    def send_inbox_message(req)
      guard(:transactional) { api_client.send_inbox_message(req) }
    end

    def send_in_app(req)
      guard(:transactional) { api_client.send_in_app(req) }
    end

    def trigger_broadcast(req)
      guard(:broadcast) do
        refuse_public_key(:broadcast)
        @api_client.trigger_broadcast(req)
      end
    end

    private

    # A prefixed key belongs to one region, so the other built-in region would
    # only get a redirect or a 401 from the server. A custom Region may be a
    # proxy, so it's trusted.
    def resolve_region(key_region, region)
      return region || Regions::US if key_region.nil?
      return KEY_REGIONS[key_region] if region.nil?

      name = KEY_REGIONS.key(region)
      if name && name != key_region
        raise ArgumentError, "region #{name} does not match the #{key_region} region of this key"
      end

      region
    end

    # The key goes out as a Bearer token, so never send it over plain http.
    def check_urls(options)
      check_https("track_url", options[:track_url])
      check_https("api_url", options[:api_url])
      return unless @region.is_a?(Regions::Region)

      check_https("region track_url", @region.track_url)
      check_https("region api_url", @region.api_url)
    end

    def check_https(name, url)
      return if url.nil? || url.to_s.empty?

      uri = begin
        URI.parse(url.to_s)
      rescue URI::InvalidURIError
        raise ArgumentError, "#{name} is not a valid URL: #{url}"
      end
      raise ArgumentError, "#{name} must start with https://" unless uri.scheme == "https"
      raise ArgumentError, "#{name} is not a valid URL: #{url}" if uri.host.to_s.empty?
    end

    def refuse_public_key(capability)
      return unless @key_kind == :pk

      raise KeyCapabilityError.new(
        capability,
        "This key can't use the App API: public keys (pk_) are for tracking only. Use a secret key (sk_)."
      )
    end

    def track_options(options)
      options.except(:api_url).merge(region: @region, url: options[:track_url])
    end

    def api_options(options)
      options.except(:track_url).merge(region: @region, url: options[:api_url])
    end

    # Turns a 401/403 into a KeyCapabilityError so a key mismatch is never a
    # bare auth failure. The original error is kept as `cause`.
    def guard(capability)
      yield
    rescue InvalidResponse => e
      raise unless %w[401 403].include?(e.code.to_s)

      reason = refusal_reason(e.message)
      raise KeyCapabilityError.new(
        capability,
        "The server refused this request to #{CAPABILITY_ACTIONS[capability]} (#{e.code}): #{reason}. " \
        "Check the key type, its IP restrictions and the workspace status.",
        e.code.to_i
      )
    end

    # The App API sends `{"errors":[{"detail":…}]}` and the Track API sends
    # `{"meta":{"error":…}}`; anything else is shown as it came.
    def refusal_reason(body)
      parsed = JSON.parse(body.to_s)
      return body unless parsed.is_a?(Hash)

      reason = parsed.dig("errors", 0, "detail") || parsed.dig("meta", "error")
      reason.is_a?(String) && !reason.empty? ? reason : body
    rescue JSON::ParserError, TypeError
      body
    end

    # Client only speaks Basic auth, so swap in a Bearer transport.
    class BearerTrackClient < Client
      def initialize(api_key, options)
        super(nil, nil, options)

        options = options.merge(url: options[:region].track_url) if options[:url].nil? || options[:url].empty?
        @client = BaseClient.new({ app_key: api_key }, options)
      end
    end
    private_constant :BearerTrackClient
  end
end
