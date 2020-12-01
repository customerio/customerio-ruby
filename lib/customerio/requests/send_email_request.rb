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
      if file.is_a?(File) || file.is_a?(Tempfile)
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
      from
      from_id
      reply_to
      reply_to_id
      bcc
      subject
      body
      plaintext_body
      amp_body
      fake_bcc
      hide_body
    )

    def invalid_field?(field)
      !REQUIRED_FIELDS.include?(field) && !OPTIONAL_FIELDS.include?(field)
    end

    def encode(data)
      Base64.strict_encode64(data)
    end
  end
end
