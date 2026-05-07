# frozen_string_literal: true

module Customerio
  class TriggerBroadcastRequest
    AUDIENCE_FIELDS = %i[recipients emails ids per_user_data data_file_url].freeze

    OPTIONAL_FIELDS = %i[data email_add_duplicates email_ignore_missing id_ignore_missing].freeze

    attr_reader :broadcast_id, :message

    def initialize(opts)
      raise ArgumentError, "broadcast_id is required" unless opts.key?(:broadcast_id)
      raise ArgumentError, "broadcast_id must be an integer" unless opts[:broadcast_id].is_a?(Integer)

      @broadcast_id = opts[:broadcast_id]
      @message = opts.select { |field, _value| valid_field?(field) }

      audience = AUDIENCE_FIELDS.select { |field| @message.key?(field) }
      if audience.length > 1
        raise ArgumentError, "only one of #{AUDIENCE_FIELDS.join(", ")} can be present"
      end
    end

    private

    def valid_field?(field)
      OPTIONAL_FIELDS.include?(field) || AUDIENCE_FIELDS.include?(field)
    end
  end
end
