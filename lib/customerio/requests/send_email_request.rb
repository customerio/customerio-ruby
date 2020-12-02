require 'base64'

module Customerio
  class SendEmailRequest
    attr_reader :message

    def initialize(opts)
      @message = opts.delete_if { |field| invalid_field?(field) }
      @message[:attachments] = {}
      @message[:headers] = {}
    end

    def attach(name, file)
      # Accepts any IO-like value that responds to `.read`.
      # StringIO, File, Tempfile, IO are all accepted.
      if file.respond_to?(:read)
        @message[:attachments][name] = encode(file.read)
      elsif file.is_a?(String)
        @message[:attachments][name] = encode(File.open(file, 'r').read)
      else
        raise "Unknown attachment type: #{file.class}"
      end
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
      plaintext_body
      amp_body
      fake_bcc
      disable_message_retention
      send_to_unsubscribed
      tracked
      queue_draft
    )

    def invalid_field?(field)
      !REQUIRED_FIELDS.include?(field) && !OPTIONAL_FIELDS.include?(field)
    end

    def encode(data)
      Base64.strict_encode64(data)
    end
  end
end
