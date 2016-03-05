require 'spec_helper'
require 'multi_json'

describe Customerio::Client do
  let(:client)   { Customerio::Client.new("SITE_ID", "API_KEY", :json => false) }
  let(:response) { double("Response", :code => 200) }

  before do
    # Dont call out to customer.io
    Customerio::Client.stub(:post).and_return(response)
    Customerio::Client.stub(:put).and_return(response)
  end

  describe "json option" do
    let(:body) { { :id => 5, :name => "Bob" } }

    it "uses json by default" do
      client = Customerio::Client.new("SITE_ID", "API_KEY")

      json = MultiJson.dump(body)
      Customerio::Client.should_receive(:put).with(
        "/api/v1/customers/5",
        {
          :basic_auth=>{:username=>"SITE_ID", :password=>"API_KEY"},
          :body=>json,
          :headers=>{"Content-Type"=>"application/json"}
        }).and_return(response)
      client.identify(body)
    end

    it "allows disabling json" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => false)

      Customerio::Client.should_receive(:put).with(
        "/api/v1/customers/5",
        {
          :basic_auth=>{:username=>"SITE_ID", :password=>"API_KEY"},
          :body=>body
        }).and_return(response)
      client.identify(body)
    end
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
      body = { :id => 5, :name => "Bob" }
      json = MultiJson.dump(body)
      Customerio::Client.should_receive(:put).with(
        "/api/v1/customers/5",
        {:basic_auth=>{:username=>"SITE_ID", :password=>"API_KEY"},
          :body=>json,
          :headers=>{"Content-Type"=>"application/json"}}).and_return(response)
      client.identify(body)
    end

    it "raises an error if PUT doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:put).and_return(double("Response", :code => 500))
      lambda { client.identify(:id => 5) }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "includes the HTTP response with raised errors" do
      response = double("Response", :code => 500, :body => "whatever")
      Customerio::Client.should_receive(:put).and_return(response)
      lambda { client.identify(:id => 5) }.should raise_error {|error|
        error.should be_a Customerio::Client::InvalidResponse
        error.response.should eq response
      }
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
          :created_at => 1374701292,
          :first_name => "Bob",
          :plan => "basic"
        }
      }).and_return(response)

      client.identify(:id => 5, :email => "customer@example.com", :created_at => 1374701292, :first_name => "Bob", :plan => "basic")
    end

    it "converts Time, DateTime, and Date objects to integer timestamps" do
      t = Time.at(1374701292).utc
      dt = t.to_datetime
      d = t.to_date
      Customerio::Client.should_receive(:put).with("/api/v1/customers/5", {
        :basic_auth => anything(),
        :body => {
          :id => 5,
          :created_at => 1374701292,
          :datetime_created_at => 1374701292,
          :date_created_at => 1374638400
        }
      }).and_return(response)

      client.identify(:id => 5, :created_at => t, :datetime_created_at => dt, :date_created_at => d)
    end

    it "requires an id attribute" do
      lambda { client.identify(:email => "customer@example.com") }.should raise_error(Customerio::Client::MissingIdAttributeError)
    end

    it 'should not raise errors when attribute keys are strings' do
      attributes = { "id" => 5 }

      lambda { client.identify(attributes) }.should_not raise_error()
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
      Customerio::Client.should_receive(:post).and_return(double("Response", :code => 500))
      lambda { client.track(5, "purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

  	it "uses the site_id and api key for basic auth" do
  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
  			:body => anything()
  		})

      client.track(5, "purchase")
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

    it "sends a POST request as json using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
  		Customerio::Client.should_receive(:post).with(
        "/api/v1/customers/5/events", {
          :basic_auth => anything(),
          :body => MultiJson.dump({
            :name => "purchase",
            :data => { :type => "socks", :price => "13.99" }
          }),
        :headers=>{"Content-Type"=>"application/json"}}).and_return(response)
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

    it "converts timestamp if timestamp is a Time" do
      time = Time.now

  		Customerio::Client.should_receive(:post).with("/api/v1/customers/5/events", {
  			:basic_auth => anything(),
  			:body => {
  				:name => "purchase",
  			  :data => { :type => "socks", :price => "13.99", :timestamp => time.to_i },
          :timestamp => time.to_i
  			}
  		}).and_return(response)

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => time)
    end

    it "doesn't send timestamp if timestamp can't be converted" do
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

  describe "#anonymous_track" do
    it "sends a POST request to the customer.io event API" do
      Customerio::Client.should_receive(:post).with("/api/v1/events", anything()).and_return(response)
      client.anonymous_track("purchase")
    end

    it "raises an error if POST doesn't return a 2xx response code" do
      Customerio::Client.should_receive(:post).and_return(double("Response", :code => 500))
      lambda { client.anonymous_track("purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "uses the site_id and api key for basic auth" do
      Customerio::Client.should_receive(:post).with("/api/v1/events", {
        :basic_auth => { :username => "SITE_ID", :password => "API_KEY" },
        :body => anything()
      })

      client.anonymous_track("purchase")
    end

    it "sends the event name" do
      Customerio::Client.should_receive(:post).with("/api/v1/events", {
        :basic_auth => anything(),
        :body => { :name => "purchase", :data => {} }
      }).and_return(response)

      client.anonymous_track("purchase")
    end

    it "sends any optional event attributes" do
      Customerio::Client.should_receive(:post).with("/api/v1/events", {
        :basic_auth => anything(),
        :body => {
          :name => "purchase",
          :data => { :type => "socks", :price => "27.99" }
        }
      }).and_return(response)

      client.anonymous_track("purchase", :type => "socks", :price => "27.99")
    end

    it "allows sending of a timestamp" do
      Customerio::Client.should_receive(:post).with("/api/v1/events", {
        :basic_auth => anything(),
        :body => {
          :name => "purchase",
          :data => { :type => "socks", :price => "27.99", :timestamp => 1561235678 },
          :timestamp => 1561235678
        }
      }).and_return(response)

      client.anonymous_track("purchase", :type => "socks", :price => "27.99", :timestamp => 1561235678)
    end

    context "too many arguments are passed" do
      it "throws an error" do
        lambda { client.anonymous_track("purchase", "text", :type => "socks", :price => "27.99") }.should raise_error(ArgumentError)
      end
    end
  end
end
