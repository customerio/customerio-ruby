# frozen_string_literal: true

module Customerio
  # Raised by UnifiedClient when its key can't do what a method asks.
  #
  # Raised before the request when the key's type rules it out (a public `pk_`
  # key can't send transactional messages). Otherwise the server's 401 or 403
  # is re-raised as this error, with the original InvalidResponse as `cause`.
  class KeyCapabilityError < StandardError
    # What the key can't do: :track or :transactional.
    attr_reader :capability
    # The HTTP status code, when the server refused the key.
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
  # `sk_us_…` / `sk_eu_…` keys the region comes from the key; an explicit
  # `region` wins, and legacy keys default to Regions::US.
  #
  # Other Track and App API methods are on #track_client and #api_client.
  class UnifiedClient
    # Keys in the shared format look like `{type}_{us|eu}_{random}_{checksum}`,
    # where type is `pk` (public) or `sk` (secret). The server checks the
    # checksum; the client only reads the prefix.
    KEY_PREFIX = /\A([a-z]{2})_(us|eu)_/

    CAPABILITY_ACTIONS = {
      track: "send tracking data",
      transactional: "send transactional messages"
    }.freeze

    attr_reader :track_client, :region

    def initialize(api_key, options = {})
      api_key = api_key.to_s.strip
      raise ArgumentError, "api_key is required" if api_key.empty?

      match = KEY_PREFIX.match(api_key)
      @key_kind = match ? match[1].to_sym : :legacy
      @region = options[:region] || (match && match[2] == "eu" ? Regions::EU : Regions::US)

      @track_client = BearerTrackClient.new(api_key, track_options(options))
      @api_client = APIClient.new(api_key, api_options(options))
    end

    # The App API client. Raises KeyCapabilityError for a public `pk_` key.
    def api_client
      if @key_kind == :pk
        raise KeyCapabilityError.new(
          :transactional,
          "This key can't use the App API: public keys (pk_) are for tracking only. Use a secret key (sk_)."
        )
      end

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
      guard(:transactional) { api_client.trigger_broadcast(req) }
    end

    private

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

      raise KeyCapabilityError.new(
        capability,
        "The server refused this request to #{CAPABILITY_ACTIONS[capability]} (#{e.code}): #{e.message}. " \
        "Check the key type, its IP restrictions and the workspace status.",
        e.code
      )
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
