require 'httparty'

module Customerio
  class Client
	  include HTTParty
	  base_uri 'https://app.customer.io'

    CustomerProxy = Struct.new("Customer", :id)

    class MissingIdAttributeError < RuntimeError; end

	  @@id_block = nil

	  def self.id(&block)
      warn "[DEPRECATION] Customerio::Client.id customization is deprecated."
      @@id_block = block
	  end

	  def self.default_config
	  	@@id_block = nil
	  end

	  def initialize(site_id, secret_key)
	    @auth = { :username => site_id, :password => secret_key }
	  end

	  def identify(*args)
      attributes = extract_attributes(args)

      if args.any?
        customer   = args.first
        attributes = attributes_from(customer).merge(attributes)
      end

	    create_or_update(attributes)
	  end

	  def track(*args)
      attributes = extract_attributes(args)

      if args.length == 1
        # Only passed in an event name, create an anonymous event
        event_name = args.first
        create_anonymous_event(event_name, attributes)
      else
        # Passed in a customer and an event name.
        # Track the event for the given customer
        customer, event_name = args

        identify(attributes_from(customer))
        create_customer_event(id_from(customer), event_name, attributes)
      end
	  end

	  private

	  def create_or_update(attributes = {})
      raise MissingIdAttributeError.new("Must provide an customer id") unless attributes[:id]

      url = customer_path(attributes[:id])
      attributes[:id] = custom_id(attributes[:id]);

	    self.class.put(url, options.merge(:body => attributes))
	  end

	  def create_customer_event(customer_id, event_name, attributes = {})
      create_event("#{customer_path(customer_id)}/events", event_name, attributes)
	  end

    def create_anonymous_event(event_name, attributes = {})
      create_event("/api/v1/events", event_name, attributes)
    end

	  def create_event(url, event_name, attributes = {})
	  	body = { :name => event_name, :data => attributes }
	    self.class.post(url, options.merge(:body => body))
	  end

	  def customer_path(id)
	    "/api/v1/customers/#{custom_id(id)}"
	  end

    def extract_attributes(args)
      args.last.is_a?(Hash) ? args.pop : {}
    end

    def attributes_from(customer)
      if id?(customer)
        { :id => customer }
      else
        {
          :id => id_from(customer),
          :email => customer.email,
          :created_at => customer.created_at.to_i
        }
      end
    end

    def id_from(customer)
      if id?(customer)
        customer
      else
        warn "[DEPRECATION] Passing a customer object to Customerio::Client is deprecated. Just pass a hash with an id key."
        customer.id
      end
    end

	  def custom_id(id)
	  	@@id_block ? @@id_block.call(id) : id
	  end

    def id?(object)
      object.is_a?(Integer) || object.is_a?(String)
    end

	  def options
	    { :basic_auth => @auth }
	  end
  end
end
