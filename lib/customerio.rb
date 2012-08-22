require "customerio/version"

module Customerio
  autoload :Client, 'customerio/client'
  autoload :Configuration, 'customerio/configuration'


  class << self
    attr_writer :configuration

    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

  end
end
