# frozen_string_literal: true

module Customerio
  class SendInboxMessageRequest
    REQUIRED_FIELDS = %i[identifiers transactional_message_id].freeze

    OPTIONAL_FIELDS = %i[
      message_data
      disable_message_retention
      queue_draft
      send_at
      language
    ].freeze

    attr_reader :message

    def initialize(opts)
      @message = opts.select { |field, _value| valid_field?(field) }
    end

    private

    def valid_field?(field)
      REQUIRED_FIELDS.include?(field) || OPTIONAL_FIELDS.include?(field)
    end
  end
end
