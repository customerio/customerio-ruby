# frozen_string_literal: true

# Based on HTTParty's HashConversions:
#
# https://github.com/jnunemaker/httparty/blob/master/lib/httparty/hash_conversions.rb
#
# License: MIT https://github.com/jnunemaker/httparty/blob/master/MIT-LICENSE

require "erb"

module Customerio
  class ParamEncoder
    # @return <String> This hash as a query string
    #
    # @example
    #   { name: "Bob",
    #     address: {
    #       street: '111 Ruby Ave.',
    #       city: 'Ruby Central',
    #       phones: ['111-111-1111', '222-222-2222']
    #     }
    #   }.to_params
    #     #=> "name=Bob&address[city]=Ruby Central&..."
    def self.to_params(hash)
      hash.to_hash.map { |k, v| normalize_param(k, v) }.join.chop
    end

    # @param key<Object> The key for the param.
    # @param value<Object> The value for the param.
    #
    # @return <String> This key value pair as a param
    #
    # @example normalize_param(:name, "Bob Jones") #=> "name=Bob%20Jones&"
    def self.normalize_param(key, value)
      param = String.new
      stack = []

      if value.respond_to?(:to_ary)
        param << value.to_ary.map { |element| normalize_param("#{key}[]", element) }.join
      elsif value.respond_to?(:to_hash)
        stack << [key, value.to_hash]
      else
        param << "#{key}=#{escape_value(value)}&"
      end

      stack.each do |parent, hash|
        hash.each do |k, v|
          if v.respond_to?(:to_hash)
            stack << ["#{parent}[#{k}]", v.to_hash]
          else
            param << normalize_param("#{parent}[#{k}]", v)
          end
        end
      end

      param
    end

    def self.escape_value(value)
      ERB::Util.url_encode(value.to_s)
    end
  end
end
