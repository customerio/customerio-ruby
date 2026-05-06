# frozen_string_literal: true

module Customerio
  class SendPushRequest
    REQUIRED_FIELDS = %i[transactional_message_id identifiers].freeze

    OPTIONAL_FIELDS = %i[
      to
      title
      message
      disable_message_retention
      send_to_unsubscribed
      queue_draft
      message_data
      send_at
      language
      image_url
      link
      sound
      custom_data
      device
      custom_device
    ].freeze

    attr_reader :message

    def initialize(opts)
      @message = opts.select { |field, _value| valid_field?(field) }
      @message[:custom_device] = opts[:device] if opts[:device]
    end

    private

    def valid_field?(field)
      REQUIRED_FIELDS.include?(field) || OPTIONAL_FIELDS.include?(field)
    end
  end
end
