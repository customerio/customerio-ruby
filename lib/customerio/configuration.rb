module Customerio
  class Configuration
    attr_accessor :api_key, :site_id, :customer_id

    def customer_id(&block)
      if block # Block given, means setting a custom id
        @customer_id = block
      else #No block given is requiesting the custom id
        @customer_id
      end
    end

  end
end
