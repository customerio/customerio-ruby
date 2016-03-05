require 'spec_helper'
require 'multi_json'


describe Customerio::Client do
  let(:client)   { Customerio::Client.new("SITE_ID", "API_KEY", :json => false) }
  let(:response) { double("Response", :code => 200) }

  def api_uri(path)
    "https://SITE_ID:API_KEY@track.customer.io#{path}"
  end

  def json(data)
    MultiJson.dump(data)
  end

  describe "json option" do
    let(:body) { { :id => 5, :name => "Bob" } }

    it "uses json by default" do
      client = Customerio::Client.new("SITE_ID", "API_KEY")

      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => json(body),
             :headers => {'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})

      client.identify(body)
    end

    it "allows disabling json" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => false)

      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => { :id => "5", :name => "Bob" }).
        to_return(:status => 200, :body => "", :headers => {})

      client.identify(body)
    end
  end

  describe "#identify" do
    it "sends a PUT request to customer.io's customer API" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
         with(:body => "id=5").
         to_return(:status => 200, :body => "", :headers => {})

      client.identify(:id => 5)
    end

    it "sends a PUT request to customer.io's customer API using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
      body = { :id => 5, :name => "Bob" }

      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => json(body),
             :headers => {'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})

      client.identify(body)
    end

    it "raises an error if PUT doesn't return a 2xx response code" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => "id=5").
        to_return(:status => 500, :body => "", :headers => {})

      lambda { client.identify(:id => 5) }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "includes the HTTP response with raised errors" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => "id=5").
        to_return(:status => 500, :body => "whatever", :headers => {})

      lambda { client.identify(:id => 5) }.should raise_error {|error|
        error.should be_a Customerio::Client::InvalidResponse
        error.response.code.should eq "500"
        error.response.body.should eq "whatever"
      }
    end

    it "sends along all attributes" do
      time = Time.now.to_i

      stub_request(:put, api_uri('/api/v1/customers/5')).with(
        :body => {
          :id => "5",
          :email => "customer@example.com",
          :created_at => time.to_s,
          :first_name => "Bob",
          :plan => "basic"
        }).to_return(:status => 200, :body => "", :headers => {})

      client.identify({
        :id => 5,
        :email => "customer@example.com",
        :created_at => time,
        :first_name => "Bob",
        :plan => "basic"
      })
    end

    it "requires an id attribute" do
      lambda { client.identify(:email => "customer@example.com") }.should raise_error(Customerio::Client::MissingIdAttributeError)
    end

    it 'should not raise errors when attribute keys are strings' do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(:body => "id=5").
        to_return(:status => 200, :body => "", :headers => {})

      attributes = { "id" => 5 }

      lambda { client.identify(attributes) }.should_not raise_error()
    end
  end

  describe "#delete" do
    it "sends a DELETE request to the customer.io's event API" do
      stub_request(:delete, api_uri('/api/v1/customers/5')).
        to_return(:status => 200, :body => "", :headers => {})

      client.delete(5)
    end
  end

  describe "#track" do
    it "raises an error if POST doesn't return a 2xx response code" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => "name=purchase").
        to_return(:status => 500, :body => "", :headers => {})

      lambda { client.track(5, "purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "uses the site_id and api key for basic auth and sends the event name" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => "name=purchase").
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase")
    end

    it "sends any optional event attributes" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(:body => {
          :name => "purchase",
          :data => {
            :type => "socks",
            :price => "13.99"
          }
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", :type => "socks", :price => "13.99")
    end

    it "copes with arrays" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(:body => {
          :name => "event",
          :data => {
            :things => ["a", "b", "c"]
          }
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "event", :things => ["a", "b", "c"])
    end

    it "copes with hashes" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(:body => {
          :name => "event",
          :data => {
            :stuff => { :a => "b" }
          }
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "event", :stuff => { :a => "b" })
    end

    it "sends a POST request as json using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
      data = { :type => "socks", :price => "13.99" }
      body = { :name => "purchase", :data => data }

      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => json(body),
             :headers => {'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", data)
    end

    it "allows sending of a timestamp" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => {
          :name => "purchase",
          :data => {
            :type => "socks",
            :price => "13.99",
            :timestamp => "1561231234"
          },
          :timestamp => "1561231234"
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234)
    end

    it "doesn't send timestamp if timestamp is in milliseconds" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => {
          :name => "purchase",
          :data => {
            :type => "socks",
            :price => "13.99",
            :timestamp => "1561231234000"
          }
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234000)
    end

    it "doesn't send timestamp if timestamp is a date" do
      date = Time.now

      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => {
          :name => "purchase",
          :data => {
            :type => "socks",
            :price => "13.99",
            :timestamp => Time.now.to_s
          }
        }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => date)
    end

    it "doesn't send timestamp if timestamp isn't an integer" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(:body => {
          :name => "purchase",
          :data => {
            :type => "socks",
            :price => "13.99",
            :timestamp => "Hello world"
          }
        }).

        to_return(:status => 200, :body => "", :headers => {})

      client.track(5, "purchase", :type => "socks", :price => "13.99", :timestamp => "Hello world")
    end

    context "tracking an anonymous event" do
      it "sends a POST request to the customer.io's anonymous event API" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(:body => "name=purchase").
          to_return(:status => 200, :body => "", :headers => {})

        client.track("purchase")
      end

      it "sends any optional event attributes" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(:body => {
            :name => "purchase",
            :data => {
              :type => "socks",
              :price => "13.99"
            }
          }).
          to_return(:status => 200, :body => "", :headers => {})

        client.track("purchase", :type => "socks", :price => "13.99")
      end

      it "allows sending of a timestamp" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(:body => {
            :name => "purchase",
            :data => {
              :type => "socks",
              :price => "13.99",
              :timestamp => "1561231234"
            },
            :timestamp => "1561231234"
          }).
          to_return(:status => 200, :body => "", :headers => {})

        client.track("purchase", :type => "socks", :price => "13.99", :timestamp => 1561231234)
      end
    end
  end

  describe "#anonymous_track" do
    it "raises an error if POST doesn't return a 2xx response code" do
      stub_request(:post, api_uri('/api/v1/events')).
        with(:body => "name=purchase").
        to_return(:status => 500, :body => "", :headers => {})

      lambda { client.anonymous_track("purchase") }.should raise_error(Customerio::Client::InvalidResponse)
    end

    it "uses the site_id and api key for basic auth and sends the event name" do
      stub_request(:post, api_uri('/api/v1/events')).
        with(:body => "name=purchase").
        to_return(:status => 200, :body => "", :headers => {})

      client.anonymous_track("purchase")
    end

    it "sends any optional event attributes" do
      stub_request(:post, api_uri('/api/v1/events')).
          with(:body => {
            :name => "purchase",
            :data => {
              :type => "socks",
              :price => "27.99"
            },
          }).

        to_return(:status => 200, :body => "", :headers => {})

      client.anonymous_track("purchase", :type => "socks", :price => "27.99")
    end

    it "allows sending of a timestamp" do
      stub_request(:post, api_uri('/api/v1/events')).
          with(:body => {
            :name => "purchase",
            :data => {
              :type => "socks",
              :price => "27.99",
              :timestamp => "1561235678"
            },
            :timestamp => "1561235678"
          }).

        to_return(:status => 200, :body => "", :headers => {})

      client.anonymous_track("purchase", :type => "socks", :price => "27.99", :timestamp => 1561235678)
    end

    context "too many arguments are passed" do
      it "throws an error" do
        lambda { client.anonymous_track("purchase", "text", :type => "socks", :price => "27.99") }.should raise_error(ArgumentError)
      end
    end
  end
end
