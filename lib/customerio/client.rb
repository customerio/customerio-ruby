require 'httparty'

module Customerio
  class Client
	  include HTTParty
	  base_uri 'https://app.customer.io'

	  @@id_block = nil

	  def self.id(&block)
      @@id_block = block
	  end

	  def self.default_config
	  	@@id_block = nil
	  end

	  def initialize(site_id, secret_key)
	    @auth = { :username => site_id, :password => secret_key }
	  end

	  def identify(customer, attributes = {})
	    create_or_update(customer, attributes)
	  end

	  def track(*args)
      hash = args.last.is_a?(Hash) ? args.pop : {}

      if args.length == 1
        # Only passed in an event name, create an anonymous event
        create_anonymous_event(args.first, hash)
      else
        # Passed in a customer and an event name.
        # Track the event for the given customer
        customer, event_name = args

        identify(customer)
        create_customer_event(customer, event_name, hash)
      end
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

	  def create_customer_event(customer, event_name, attributes = {})
      create_event("#{customer_path(customer)}/events", event_name, attributes)
	  end

    def create_anonymous_event(event_name, attributes = {})
      create_event("/api/v1/events", event_name, attributes)
    end

	  def create_event(url, event_name, attributes = {})
	  	body = { :name => event_name, :data => attributes }
	    self.class.post(url, options.merge(:body => body))
	  end

	  def customer_path(customer)
	    "/api/v1/customers/#{id(customer)}"
	  end

	  def id(customer)
	  	@@id_block ? @@id_block.call(customer) : customer.id
	  end

	  def options
	    { :basic_auth => @auth }
	  end
  end
end
