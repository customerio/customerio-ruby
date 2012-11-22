require 'spec_helper'

describe Customerio::Client do
	let(:client)   { Customerio::Client.new("SITE_ID", "API_KEY") }
	let(:customer) { mock("Customer", :id => 5, :email => "customer@example.com", :created_at => Time.now) }
  let(:response) { mock("Response", code: 200) }

  before do
    # Dont call out to customer.io
    Customerio::Client.stub(:post).and_return(response)
    Customerio::Client.stub(:put).and_return(response)
  end

  describe ".base_uri" do
  	it "should be set to customer.io's api" do
  		Customerio::Client.base_uri.should == "https://app.customer.io"
  	end
  end

  describe "#identify" do
    it "sends a PUT request to customer.io's customer API" do
      Customerio::Client.should_receive(:put).with("/api/v1/customers/5", anything()).and_return(response)
      client.identify(:id => 5)
    end

    it "raises an error if PUT doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:put).and_return(mock("Response", code: 500))
      lambda { client.identify(:id => 5) }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "uses the site_id and api key for basic auth" do
      Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
        :basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
        :body => anything()
      }).and_return(response)

      client.identify(:id => 5)
    end

    it "sends along all attributes" do
      Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
        :basic_auth => anything(),
        :body => {
          :id => 5,
          :email => "customer@example.com",
          :created_at => Time.now.to_i,
          :first_name => "Bob",
          :plan => "basic"
        }.stringify_keys
      }).and_return(response)

      client.identify(:id => 5, :email => "customer@example.com", :created_at => Time.now.to_i, :first_name => "Bob", :plan => "basic")
    end

    it "requires an id attribute" do
      lambda { client.identify(:email => "customer@example.com") }.should raise_error(Customerio::Client::MissingIdAttributeError)
    end

    context "customer object passed in" do
      it "sends the customer's id, email, and created_at timestamp" do
        Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
          :basic_auth => anything(),
          :body => {
            :id => 5,
            :email => "customer@example.com",
            :created_at => Time.now.to_i
          }.stringify_keys
        }).and_return(response)

        client.identify(customer)
      end

      it "sends any optional attributes" do
        Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
          :basic_auth => anything(),
          :body => {
            :id => 5,
            :email => "customer@example.com",
            :created_at => Time.now.to_i,
            :first_name => "Bob",
            :plan => "basic"
          }.stringify_keys
        }).and_return(response)

        client.identify(customer, :first_name => "Bob", :plan => "basic")
      end
    end

    context "client has customized identities" do
      before do
        Customerio::Client.id do |customer_id|
          "production_#{customer_id}"
        end
      end

      it "identifies the customer with the identification method" do
        Customerio::Client.should_receive(:put).with("/api/v1/customers/production_5", {
          :basic_auth => anything(),
          :body => {
            :id => "production_5",
            :email => "customer@example.com",
            :created_at => Time.now.to_i
          }.stringify_keys
        }).and_return(response)

        client.identify(customer)
      end

      it "uses custom identity when using a pure hash" do
        Customerio::Client.should_receive(:put).with("/api/v1/customers/production_5", {
          :basic_auth => anything(),
          :body => {
            :id => "production_5",
            :email => "customer@example.com",
            :created_at => Time.now.to_i
          }.stringify_keys
        }).and_return(response)

        client.identify(:id => 5, :email => "customer@example.com", :created_at => Time.now.to_i)
      end
    end
  end

  describe "#track" do
  	it "sends a POST request to the customer.io's event API" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", anything()).and_return(response)
      client.track(customer, "purchase")
  	end

    it "raises an error if POST doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:post).and_return(mock("Response", code: 500))
      lambda { client.track(customer, "purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

  	it "calls identify with the user's attributes to ensure they've been properly identified" do
  		client.should_receive(:identify).with({ :id => 5, :email => "customer@example.com", :created_at => Time.now.to_i }.stringify_keys).and_return(response)
  		client.track(customer, "purchase")
  	end

  	it "uses the site_id and api key for basic auth" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
  			:body => anything()
  		})

      client.track(customer, "purchase")
  	end

  	it "sends the event name" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => { :name => "purchase", :data => {} }
  		}).and_return(response)

      client.track(customer, "purchase")
  	end

  	it "sends any optional event attributes" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99" }.stringify_keys
  			}
  		}).and_return(response)

      client.track(customer, "purchase", :type => "socks", :price => "13.99")
  	end

    it "allows tracking by customer id as well" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99" }.stringify_keys
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99")
    end

    context "client has customized identities" do
      before do
        Customerio::Client.id do |customer_id|
          "production_#{customer_id}"
        end
      end

      it "identifies the customer with the identification method" do
        Customerio::Client.should_receive(:post).with("/api/v1/customers/production_5/events", {
          :basic_auth => anything(),
          :body => anything()
        }).and_return(response)

        client.track(customer, "purchase")
      end

      it "uses the identification method when tracking by id" do
        Customerio::Client.should_receive(:post).with("/api/v1/customers/production_5/events", {
          :basic_auth => anything(),
          :body => anything()
        }).and_return(response)

        client.track(5, "purchase")
      end
    end

    context "tracking an anonymous event" do
      it "sends a POST request to the customer.io's anonymous event API" do
        Customerio::Client.should_receive(:post).with("/api/v1/events", anything()).and_return(response)
        client.track("purchase")
      end

      it "uses the site_id and api key for basic auth" do
        Customerio::Client.should_receive(:post).with("/api/v1/events", {
          :basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
          :body => anything()
        }).and_return(response)

        client.track("purchase")
      end

      it "sends the event name" do
        Customerio::Client.should_receive(:post).with("/api/v1/events", {
          :basic_auth => anything(),
          :body => { :name => "purchase", :data => {} }
        }).and_return(response)

        client.track("purchase")
      end

      it "sends any optional event attributes" do
        Customerio::Client.should_receive(:post).with("/api/v1/events", {
          :basic_auth => anything(),
          :body => {
            :name => "purchase",
            :data => { :type => "socks", :price => "13.99" }.stringify_keys
          }
        }).and_return(response)

        client.track("purchase", :type => "socks", :price => "13.99")
      end
    end
  end
end
