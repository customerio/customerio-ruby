# frozen_string_literal: true

require "base64"

module Customerio
  class SendEmailRequest
    REQUIRED_FIELDS = %i[to identifiers].freeze

    OPTIONAL_FIELDS = %i[
      transactional_message_id
      message_data
      headers
      preheader
      from
      reply_to
      bcc
      subject
      body
      body_plain
      body_amp
      fake_bcc
      disable_message_retention
      send_to_unsubscribed
      tracked
      queue_draft
      disable_css_preprocessing
      send_at
      language
    ].freeze

    attr_reader :message

    def initialize(opts)
      @message = opts.select { |field, _value| valid_field?(field) }
      @message[:attachments] = {}
      @message[:headers] = {}
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
