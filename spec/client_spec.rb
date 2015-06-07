require 'spec_helper'

describe Customerio::Client do
	let(:client)   { Customerio::Client.new("SITE_ID", "API_KEY") }
  let(:response) { mock("Response", :code => 200) }

  before do
    # Dont call out to customer.io
    Customerio::Client.stub(:post).and_return(response)
    Customerio::Client.stub(:put).and_return(response)
  end

  describe ".base_uri" do
  	it "should be set to customer.io's api" do
  		Customerio::Client.base_uri.should == "https://track.customer.io"
  	end
  end

  describe "#identify" do
    it "sends a PUT request to customer.io's customer API" do
      Customerio::Client.should_receive(:put).with("/api/v1/customers/5", anything()).and_return(response)
      client.identify(:id => 5)
    end

    it "sends a PUT request to customer.io's customer API using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
      Customerio::Client.should_receive(:put).with(
        "/api/v1/customers/5",
        {:basic_auth=>{:username=>"SITE_ID", :password=>"API_KEY"},
          :body=>"{\"id\":5,\"name\":\"Bob\"}",
          :headers=>{"Content-Type"=>"application/json"}}).and_return(response)
      client.identify(:id => 5, :name => "Bob")
    end

    it "raises an error if PUT doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:put).and_return(mock("Response", :code => 500))
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
        }
      }).and_return(response)

      client.identify(:id => 5, :email => "customer@example.com", :created_at => Time.now.to_i, :first_name => "Bob", :plan => "basic")
    end

    it "requires an id attribute" do
      lambda { client.identify(:email => "customer@example.com") }.should raise_error(Customerio::Client::MissingIdAttributeError)
    end
  end

  describe "#delete" do
  	it "sends a DELETE request to the customer.io's event API" do
  		Customerio::Client.should_receive(:delete).with("/api/v1/customers/5", anything()).and_return(response)
      client.delete(5)
  	end
  end

  describe "#track" do
  	it "sends a POST request to the customer.io's event API" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", anything()).and_return(response)
      client.track(5, "purchase")
  	end

    it "raises an error if POST doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:post).and_return(mock("Response", :code => 500))
      lambda { client.track(5, "purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

  	it "uses the site_id and api key for basic auth" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
  			:body => anything()
  		})

      client.track(5, "purchase")
  	end

    it "sends JSON serialized data with a POST request to customer.io's customer API using json headers" do

      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
      Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
        :basic_auth=>{:username=>"SITE_ID", :password=>"API_KEY"},
        :body=>"{\"name\":\"purchase\",\"data\":{\"type\":\"socks\",\"price\":\"13.99\"}}",
        :headers=>{"Content-Type"=>"application/json"}
      }).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99")
    end

  	it "sends the event name" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => { :name => "purchase", :data => {} }
  		}).and_return(response)

      client.track(5, "purchase")
  	end

  	it "sends any optional event attributes" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99" }
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99")
  	end

  	it "allows sending of a timestamp" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99", :timestamp => 1561231234 },
          :timestamp => 1561231234
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234)
  	end

    it "doesn't send timestamp if timestamp is in milliseconds" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99", :timestamp => 1561231234000 }
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234000)
    end

    it "doesn't send timestamp if timestamp is a date" do
      date = Time.now

  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99", :timestamp => date }
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => date)
    end

    it "doesn't send timestamp if timestamp isn't a integer" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99", :timestamp => "Hello world" }
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => "Hello world")
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
            :data => { :type => "socks", :price => "13.99" }
          }
        }).and_return(response)

        client.track("purchase", :type => "socks", :price => "13.99")
      end

      it "allows sending of a timestamp" do
        Customerio::Client.should_receive(:post).with("/api/v1/events", {
          :basic_auth => anything(),
          :body => {
            :name => "purchase",
  			    :data => { :type => "socks", :price => "13.99", :timestamp => 1561231234 },
            :timestamp => 1561231234
          }
        }).and_return(response)

        client.track("purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234)
      end
    end
  end
end
