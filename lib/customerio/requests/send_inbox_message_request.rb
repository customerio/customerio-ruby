require 'base64'

module Customerio
  class SendInboxMessageRequest
    attr_reader :message

    def initialize(opts)
      @message = opts.delete_if { |field| invalid_field?(field) }
    end

    private

    REQUIRED_FIELDS = %i(identifiers transactional_message_id)

    OPTIONAL_FIELDS = %i(
      message_data
      disable_message_retention
      queue_draft
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
