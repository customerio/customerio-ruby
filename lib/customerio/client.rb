require 'httparty'

module Customerio
  class Client
	  include HTTParty
	  base_uri 'https://app.customer.io'

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
	      :id => customer.id,
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
	    "/api/v1/customers/#{customer.id}"
	  end

	  def options
	    { :basic_auth => @auth }
	  end
  end
end