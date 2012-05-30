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
	  	@@id_block ? @@id_block.call(customer) : customer.id
	  end

	  def options
	    { :basic_auth => @auth }
	  end
  end
end
