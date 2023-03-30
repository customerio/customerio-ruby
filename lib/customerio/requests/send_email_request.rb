require 'base64'

module Customerio
  class SendEmailRequest
    attr_reader :message

    def initialize(opts)
      @message = opts.delete_if { |field| invalid_field?(field) }
      @message[:attachments] = {}
      @message[:headers] = {}
    end

    def attach(name, data, encode: true)
      raise "attachment #{name} already exists" if @message[:attachments].has_key?(name)
      @message[:attachments][name] = encode ? Base64.strict_encode64(data) : data
    end

    private

    REQUIRED_FIELDS = %i(to identifiers)

    OPTIONAL_FIELDS = %i(
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
    )

    def invalid_field?(field)
      !REQUIRED_FIELDS.include?(field) && !OPTIONAL_FIELDS.include?(field)
    end

    def encode(data)
      Base64.strict_encode64(data)
    end
  end
end
