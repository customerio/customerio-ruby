require 'httparty'

module Customerio
  class Client
	  include HTTParty
    attr_accessor :auth

	  base_uri 'https://app.customer.io'

	  @@id_block = nil

    # <b>DEPRECATED:</b> Please use <tt>Customerio.configure.customer_id</tt> instead.
	  def self.id(&block)
      warn "[DEPRECATION] setting the customer_id using Client.id is deprecated, please use Customerio.config.customer_id instead."
      @@id_block = block
	  end

    # <b>DEPRECATED:</b> Using 'Customerio.default_config' is deprecated, please use <tt>Customerio.configuration = nil</tt> instead"
	  def self.default_config
      warn "[DEPRECATION] Using 'Customerio.default_config' is deprecated, please use 'Customerio.configuration = nil' instead"
      Customerio.configuration = nil
      @@id_block = nil
	  end

	  def initialize(site_id=nil, api_key=nil)
      site_id = site_id || Customerio.configuration.site_id
      api_key = api_key || Customerio.configuration.api_key
	    @auth = { :username => site_id, :password => api_key }
	  end

	  def identify(customer, attributes = {})
	    create_or_update(customer, attributes)
	  end

	  def track(customer, event_name, hash = {})
	    identify(customer)
	    create_event(customer, event_name, hash)
	  end

	  private

	  def create_or_update(customer, attributes = {})
	    body = {
	      :id => id(customer),
	      :email => customer.email,
	      :created_at => customer.created_at.to_i
	    }.merge(attributes)

	    self.class.put(customer_path(customer), options.merge(:body => body))
	  end

	  def create_event(customer, event_name, attributes = {})
	  	body = { :name => event_name, :data => attributes }
	    self.class.post("#{customer_path(customer)}/events", options.merge(:body => body))
	  end

	  def customer_path(customer)
	    "/api/v1/customers/#{id(customer)}"
	  end

	  def id(customer)
      if !@@id_block.nil?
        warn "[DEPRECATION] using 'Customerio::Client.id' is deprecated, you might have used Customerio::Client.id instead of Customerio.configure."
        return @@id_block.call(customer)
      end

      if Customerio.configuration.customer_id
        Customerio.configuration.customer_id.call(customer)
      else
        customer.id
      end
	  end

	  def options
	    { :basic_auth => @auth }
	  end
  end
end
