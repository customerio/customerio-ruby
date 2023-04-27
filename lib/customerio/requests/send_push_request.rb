module Customerio
  class SendPushRequest
    attr_reader :message

    def initialize(opts)
      @message = opts.delete_if { |field| invalid_field?(field) }
      @message[:custom_device] = opts[:device] if opts[:device]
    end

    private

    REQUIRED_FIELDS = %i(transactional_message_id identifiers)

    OPTIONAL_FIELDS = %i(
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
    )

    def invalid_field?(field)
      !REQUIRED_FIELDS.include?(field) && !OPTIONAL_FIELDS.include?(field)
    end
  end
end
