# frozen_string_literal: true

require "base64"

module Customerio
  class SendSMSRequest
    REQUIRED_FIELDS = %i[identifiers transactional_message_id].freeze

    OPTIONAL_FIELDS = %i[
      message_data
      from
      to
      disable_message_retention
      send_to_unsubscribed
      tracked
      queue_draft
      send_at
      language
    ].freeze

    attr_reader :message

    def initialize(opts)
      @message = opts.select { |field, _value| valid_field?(field) }
      @message[:attachments] ||= {}
    end

    def attach(name, data, encode: true)
      raise ArgumentError, "attachment #{name} already exists" if @message[:attachments].key?(name)

      @message[:attachments][name] = encode ? Base64.strict_encode64(data) : data
    end

    private

    def valid_field?(field)
      REQUIRED_FIELDS.include?(field) || OPTIONAL_FIELDS.include?(field)
    end
  end
end
