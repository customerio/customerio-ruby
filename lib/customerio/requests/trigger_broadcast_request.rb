module Customerio
  class TriggerBroadcastRequest
    attr_reader :broadcast_id, :payload

    def initialize(broadcast_id:, payload:{})
      @broadcast_id = broadcast_id
      @payload = payload.delete_if { |field| invalid_field?(field) }

      validate_broadcast_id
      validate_xor_recipients
    end

    private

    OPTIONAL_FIELDS = [:data, :email_add_duplicates, :email_ignore_missing, :id_ignore_missing].freeze

    # we're not validating the structure, just that only one is present
    ONLY_ONE_ALLOWED = [
      :recipients,
      :emails,
      :ids,
      :per_user_data,
      :data_file_url
    ].freeze

    def invalid_field?(field)
      !OPTIONAL_FIELDS.include?(field) && !ONLY_ONE_ALLOWED.include?(field)
    end

    def validate_broadcast_id
      raise 'broadcast id is required' unless broadcast_id
      raise 'broadcast id must be an integer' unless broadcast_id.is_a?(Integer)
    end

    def validate_xor_recipients
      present = ONLY_ONE_ALLOWED.select { |field| payload.key?(field) }

      raise "Only one of #{arr.join(', ')} can be present" if present.length > 1
    end
  end
end
