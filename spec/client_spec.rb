require 'spec_helper'

describe Customerio::Client do
	let(:client)   { Customerio::Client.new("SITE_ID", "API_KEY") }
	let(:customer) { mock("Customer", :id => 5, :email => "customer@example.com", :created_at => Time.now) }

  describe ".base_uri" do
  	it "should be set to customer.io's api" do
  		Customerio::Client.base_uri.should == "https://app.customer.io"
  	end
  end

  describe "initialization of client" do

    it "by config object" do
      Customerio.configure do |config|
        config.api_key = "API_KEY"
        config.site_id = "SITE_ID"
      end
      client = Customerio::Client.new
      client.auth[:username].should eql("SITE_ID")
      client.auth[:password].should eql("API_KEY")
    end

    it "by providing site_id and api_key directly" do
      Customerio.configuration = nil
      client = Customerio::Client.new("SITE_ID","API_KEY")
      client.auth[:username].should eql("SITE_ID")
      client.auth[:password].should eql("API_KEY")
    end
  end

  describe "#identify" do
  	it "sends a PUT request to customer.io's customer API" do
  		Customerio::Client.should_receive(:put).with("/api/v1/customers/5", anything())
      client.identify(customer)
  	end

  	it "uses the site_id and api key for basic auth" do
  		Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
  			:basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
  			:body => anything()
  		})

      client.identify(customer)
  	end

  	it "sends the customer's id, email, and created_at timestamp" do
  		Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
  			:basic_auth => anything(),
  			:body => {
  				:id => 5,
	        :email => "customer@example.com",
	        :created_at => Time.now.to_i
  			}
  		})

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
  			}
  		})

      client.identify(customer, :first_name => "Bob", :plan => "basic")
  	end

    context "client has customized identities" do
      context "using deprecated, but still supported configuration" do
        before do
          Customerio::Client.id do |customer|
            "production_#{customer.id}"
          end
        end

        after do
          Customerio::Client.default_config
        end

        it "identifies the customer with the identification method" do
          Customerio::Client.should_receive(:put).with("/api/v1/customers/production_5", {
            :basic_auth => anything(),
            :body => {
              :id => "production_5",
              :email => "customer@example.com",
              :created_at => Time.now.to_i
            }
          })

          client.identify(customer)
        end
      end

      context "using preferred configuration" do
        before do
          Customerio.configure do |config|
            config.customer_id do |customer|
              "production_#{customer.id}"
            end
          end
        end

        it "identifies the customer with the identification method" do
          Customerio::Client.should_receive(:put).with("/api/v1/customers/production_5", {
            :basic_auth => anything(),
            :body => {
              :id => "production_5",
              :email => "customer@example.com",
              :created_at => Time.now.to_i
            }
          })

          client.identify(customer)
        end
      end
    end
  end

  describe "#track" do
  	before do
  		# Don't actually send identify requests
  		Customerio::Client.stub(:put)
  	end

  	it "sends a POST request to the customer.io's event API" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", anything())
      client.track(customer, "purchase")
  	end

  	it "calls identify with the user to ensure they've been properly identified" do
  		Customerio::Client.stub(:post) # don't send the request
  		client.should_receive(:identify).with(customer)
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
  		})

      client.track(customer, "purchase")
  	end

  	it "sends any optional event attributes" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99" }
  			}
  		})

      client.track(customer, "purchase", :type => "socks", :price => "13.99")
  	end

    context "client has customized identities" do
      before do
        Customerio.configure do |config|
          config.customer_id do |customer|
            "production_#{customer.id}"
          end
        end
      end

      it "identifies the customer with the identification method" do
        Customerio::Client.should_receive(:post).with("/api/v1/customers/production_5/events", {
        :basic_auth => anything(),
        :body => anything()
      })

      client.track(customer, "purchase")
      end
    end
  end
end
