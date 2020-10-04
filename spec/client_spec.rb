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

  describe "#suppress" do
    it "sends a POST request to the customer.io's suppress API" do
      stub_request(:post, api_uri('/api/v1/customers/5/suppress')).
        to_return(:status => 200, :body => "", :headers => {})

      client.suppress(5)
    end
  end

  describe "#unsuppress" do
    it "sends a POST request to the customer.io's unsuppress API" do
      stub_request(:post, api_uri('/api/v1/customers/5/unsuppress')).
        to_return(:status => 200, :body => "", :headers => {})

      client.unsuppress(5)
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

  describe "#devices" do
    it "allows for the creation of a new device" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

      client.add_device(5, "androidDeviceID", "ios", {:last_used=>1561235678})
      client.add_device(5, "iosDeviceID", "android")
    end
    it "requires a valid customer_id when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.add_device("", "ios", "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(nil, "ios", "myDeviceID", {:last_used=>1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid token when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.add_device(5, "", "ios") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(5, nil, "ios", {:last_used=>1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid platform when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.add_device(5, "token", "") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(5, "toke", nil, {:last_used=>1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "accepts a nil data param" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

        client.add_device(5, "ios", "myDeviceID", nil)
    end
    it "fails on invalid data param" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.add_device(5, "ios", "myDeviceID", 1000) }.should raise_error(Customerio::Client::ParamError)
    end
    it "supports deletion of devices by token" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(:status => 200, :body => "", :headers => {})

      client.delete_device(5, "myDeviceID")
    end
    it "requires a valid customer_id when deleting" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.delete_device("", "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.delete_device(nil, "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid device_id when deleting" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(:status => 200, :body => "", :headers => {})

       lambda { client.delete_device(5, "") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.delete_device(5, nil) }.should raise_error(Customerio::Client::ParamError)
    end
  end

  describe "#manual_segments" do

    client = Customerio::Client.new("SITE_ID", "API_KEY", :json=>true)

    it "allows adding customers to a manual segment" do
      stub_request(:post, api_uri('/api/v1/segments/1/add_customers')).to_return(:status => 200, :body => "", :headers => {})

      client.add_to_segment(1, ["customer1", "customer2", "customer3"])
    end
    it "requires a valid segment id when adding customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/add_customers')).to_return(:status => 200, :body => "", :headers => {})

      lambda { client.add_to_segment("not_valid", ["customer1", "customer2", "customer3"]).should raise_error(Customerio::Client::ParamError) }
    end
    it "requires a valid customer list when adding customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/add_customers')).to_return(:status => 200, :body => "", :headers => {})

      lambda { client.add_to_segment(1, "not_valid").should raise_error(Customerio::Client::ParamError) }
    end
    it "coerces non-string values to strings when adding customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/add_customers')).with(:body=>json({:ids=>["1", "2", "3"]})).to_return(:status => 200, :body => "", :headers => {})

      client.add_to_segment(1, [1, 2, 3])
    end
    it "allows removing customers from a manual segment" do
      stub_request(:post, api_uri('/api/v1/segments/1/remove_customers')).to_return(:status => 200, :body => "", :headers => {})

      client.remove_from_segment(1, ["customer1", "customer2", "customer3"])
    end
    it "requires a valid segment id when removing customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/remove_customers')).to_return(:status => 200, :body => "", :headers => {})

      lambda { client.remove_from_segment("not_valid", ["customer1", "customer2", "customer3"]).should raise_error(Customerio::Client::ParamError) }
    end
    it "requires a valid customer list when removing customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/remove_customers')).to_return(:status => 200, :body => "", :headers => {})

      lambda { client.remove_from_segment(1, "not_valid").should raise_error(Customerio::Client::ParamError) }
    end
    it "coerces non-string values to strings when removing customers" do
      stub_request(:post, api_uri('/api/v1/segments/1/remove_customers')).with(:body=>json({:ids=>["1", "2", "3"]})).to_return(:status => 200, :body => "", :headers => {})

      client.remove_from_segment(1, [1, 2, 3])
    end
  end

  describe "#track_push_notification_open" do

    attr_accessor :client, :attributes

    before(:each) do
      @client = Customerio::Client.new("SITE_ID", "API_KEY", :json => true)
      @attributes = {
        :delivery_id => 'foo',
        :device_id => 'bar',
        :timestamp => Time.now.to_i
      }
    end

    it "sends a POST request to customer.io's /push/events endpoint" do
      stub_request(:post, api_uri('/push/events')).
        with(
          :body => json(attributes.merge({
              :event => 'opened'
          })),
          :headers => {
            'Content-Type' => 'application/json'
          }).
        to_return(:status => 200, :body => "", :headers => {})

      client.track_push_notification_open(attributes)
    end

    it "should raise if delivery_id is invalid" do
      stub_request(:post, api_uri('/push/events')).
        to_return(:status => 200, :body => "", :headers => {})

      expect {
        client.track_push_notification_open(attributes.merge({ :delivery_id => nil }))
      }.to raise_error(Customerio::Client::ParamError, 'delivery_id must be a non-empty string')

      expect {
        client.track_push_notification_open(attributes.merge({ :delivery_id => '' }))
      }.to raise_error(Customerio::Client::ParamError, 'delivery_id must be a non-empty string')
    end

    it "should raise if device_id is invalid" do
      stub_request(:post, api_uri('/push/events')).
        to_return(:status => 200, :body => "", :headers => {})

      expect {
        client.track_push_notification_open(attributes.merge({ :device_id => nil }))
      }.to raise_error(Customerio::Client::ParamError, 'device_id must be a non-empty string')

      expect {
        client.track_push_notification_open(attributes.merge({ :device_id => '' }))
      }.to raise_error(Customerio::Client::ParamError, 'device_id must be a non-empty string')
    end

    it "should raise if timestamp is invalid" do
      stub_request(:post, api_uri('/push/events')).
        to_return(:status => 200, :body => "", :headers => {})

      expect {
        client.track_push_notification_open(attributes.merge({ :timestamp => nil }))
      }.to raise_error(Customerio::Client::ParamError, 'timestamp must be a valid timestamp')

      expect {
        client.track_push_notification_open(attributes.merge({ :timestamp => 999999999 }))
      }.to raise_error(Customerio::Client::ParamError, 'timestamp must be a valid timestamp')

      expect {
        client.track_push_notification_open(attributes.merge({ :timestamp => 100000000000 }))
      }.to raise_error(Customerio::Client::ParamError, 'timestamp must be a valid timestamp')
    end
  end
end
