# frozen_string_literal: true

module Customerio
  class CreateImportRequest
    REQUIRED_FIELDS = %i[data_file_url type].freeze

    OPTIONAL_FIELDS = %i[name identifier description people_to_process data_to_process object_type_id].freeze

    attr_reader :message

    def initialize(opts)
      REQUIRED_FIELDS.each do |field|
        raise ArgumentError, "#{field} is required" if blank?(opts[field])
      end

      @message = opts.select { |field, _value| valid_field?(field) }
    end

    private

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def valid_field?(field)
      REQUIRED_FIELDS.include?(field) || OPTIONAL_FIELDS.include?(field)
    end
  end
end
