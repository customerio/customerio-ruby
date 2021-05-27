require 'spec_helper'
require 'multi_json'
require 'base64'

describe Customerio::Client do
  let(:site_id) { "SITE_ID" }
  let(:api_key) { "API_KEY" }

  let(:client)   { Customerio::Client.new(site_id, api_key) }
  let(:response) { double("Response", code: 200) }

  def api_uri(path)
    "https://track.customer.io#{path}"
  end

  def request_headers
    token = Base64.strict_encode64("#{site_id}:#{api_key}")
    { 'Authorization': "Basic #{token}", 'Content-Type': 'application/json' }
  end

  def json(data)
    MultiJson.dump(data)
  end

  it "the base client is initialised with the correct values when no region is passed in" do
    site_id = "SITE_ID"
    api_key = "API_KEY"

    expect(Customerio::BaseClient).to(
      receive(:new)
        .with(
          { site_id: site_id, api_key: api_key },
          {
            region: Customerio::Regions::US,
            url: Customerio::Regions::US.track_url
          }
        )
    )

    client = Customerio::Client.new(site_id, api_key)
  end

  it "raises an error when an incorrect region is passed in" do
    expect {
      Customerio::Client.new("siteid", "apikey", region: :au)
    }.to raise_error /region must be an instance of Customerio::Regions::Region/
  end

  [Customerio::Regions::US, Customerio::Regions::EU].each do |region|
    it "the base client is initialised with the correct values when the region \"#{region}\" is passed in" do
      site_id = "SITE_ID"
      api_key = "API_KEY"

      expect(Customerio::BaseClient).to(
        receive(:new)
          .with(
            { site_id: site_id, api_key: api_key },
            {
              region: region,
              url: region.track_url
            }
          )
      )

      client = Customerio::Client.new(site_id, api_key, { region: region })
    end
  end

  it "uses json by default" do
    body = { id: 5, name: "Bob" }
    client = Customerio::Client.new("SITE_ID", "API_KEY")

    stub_request(:put, api_uri('/api/v1/customers/5')).
      with(body: json(body),
           headers: {'Content-Type'=>'application/json'}).
      to_return(status: 200, body: "", headers: {})

    client.identify(body)
  end

  describe "headers" do
    let(:body) { { id: 1, token: :test } }

    it "sends the basic headers, base64 encoded with the request" do
      client = Customerio::Client.new("SITE_ID", "API_KEY")

      stub_request(:put, api_uri('/api/v1/customers/1')).
        with(body: json(body), headers: request_headers).
        to_return(status: 200, body: "", headers: {})

      client.identify(body)
    end
  end

  describe "#identify" do
    it "sends a PUT request to customer.io's customer API" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
         with(body: json(id: "5")).
         to_return(status: 200, body: "", headers: {})

      client.identify(id: "5")
    end

    it "escapes customer IDs" do
      stub_request(:put, api_uri('/api/v1/customers/5%20')).
         with(body: json({ id: "5 " })).
         to_return(status: 200, body: "", headers: {})

      client.identify(id: "5 ")

      stub_request(:put, api_uri('/api/v1/customers/5%2F')).
         with(body: { id: "5/" }).
         to_return(status: 200, body: "", headers: {})
      client.identify(id: "5/")
    end

    it "sends a PUT request to customer.io's customer API using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", json: true)
      body = { id: 5, name: "Bob" }

      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(body: json(body),
             headers: {'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})

      client.identify(body)
    end

    it "raises an error if PUT doesn't return a 2xx response code" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(body: json(id: 5)).
        to_return(status: 500, body: "", headers: {})

      lambda { client.identify(id: 5) }.should raise_error(Customerio::InvalidResponse)
    end

    it "includes the HTTP response with raised errors" do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(body: json(id: 5)).
        to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.identify(id: 5) }.should raise_error {|error|
        error.should be_a Customerio::InvalidResponse
        error.code.should eq "500"
        error.message.should eq "Server unavailable"
      }
    end

    it "sends along all attributes" do
      time = Time.now.to_i

      stub_request(:put, api_uri('/api/v1/customers/5')).with(
        body: json({
          id: 5,
          email: "customer@example.com",
          created_at: time,
          first_name: "Bob",
          plan: "basic"
        })).to_return(status: 200, body: "", headers: {})

      client.identify({
        id: 5,
        email: "customer@example.com",
        created_at: time,
        first_name: "Bob",
        plan: "basic"
      })
    end

    it "requires an id attribute" do
      lambda { client.identify(email: "customer@example.com") }.should raise_error(Customerio::Client::MissingIdAttributeError)
      lambda { client.identify(id: "") }.should raise_error(Customerio::Client::MissingIdAttributeError)
    end

    it 'should not raise errors when attribute keys are strings' do
      stub_request(:put, api_uri('/api/v1/customers/5')).
        with(body: json(id: 5)).
        to_return(status: 200, body: "", headers: {})

      attributes = { "id" => 5 }

      lambda { client.identify(attributes) }.should_not raise_error()
    end
  end

  describe "#delete" do
    it "sends a DELETE request to the customer.io's event API" do
      stub_request(:delete, api_uri('/api/v1/customers/5')).
        to_return(status: 200, body: "", headers: {})

      client.delete(5)
    end

    it "throws an error when customer_id is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.delete(" ") }.should raise_error(Customerio::Client::ParamError, "customer_id must be a non-empty string")
    end

    it "escapes customer IDs" do
      stub_request(:delete, api_uri('/api/v1/customers/5%20')).
         to_return(status: 200, body: "", headers: {})

      client.delete("5 ")
    end
  end

  describe "#suppress" do
    it "sends a POST request to the customer.io's suppress API" do
      stub_request(:post, api_uri('/api/v1/customers/5/suppress')).
        to_return(status: 200, body: "", headers: {})

      client.suppress(5)
    end

    it "throws an error when customer_id is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.suppress(" ") }.should raise_error(Customerio::Client::ParamError, "customer_id must be a non-empty string")
    end
  end

  describe "#unsuppress" do
    it "sends a POST request to the customer.io's unsuppress API" do
      stub_request(:post, api_uri('/api/v1/customers/5/unsuppress')).
        to_return(status: 200, body: "", headers: {})

      client.unsuppress(5)
    end

    it "throws an error when customer_id is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.suppress(" ") }.should raise_error(Customerio::Client::ParamError, "customer_id must be a non-empty string")
    end
  end

  describe "#track" do
    it "raises an error if POST doesn't return a 2xx response code" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json(name: "purchase", data: {})).
        to_return(status: 500, body: "", headers: {})

      lambda { client.track(5, "purchase") }.should raise_error(Customerio::InvalidResponse)
    end

    it "throws an error when customer_id or event_name is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.track(" ", "test_event") }.should raise_error(Customerio::Client::ParamError, "customer_id must be a non-empty string")
      lambda { client.track(5, " ") }.should raise_error(Customerio::Client::ParamError, "event_name must be a non-empty string")
    end

    it "uses the site_id and api key for basic auth and sends the event name" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json(name: "purchase", data: {})).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase")
    end

    it "sends any optional event attributes" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(body: json({
          name: "purchase",
          data: {
            type: "socks",
            price: "13.99"
          }
        })).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", type: "socks", price: "13.99")
    end

    it "copes with arrays" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(body: {
          name: "event",
          data: {
            things: ["a", "b", "c"]
          }
        }).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "event", things: ["a", "b", "c"])
    end

    it "copes with hashes" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
         with(body: {
          name: "event",
          data: {
            stuff: { a: "b" }
          }
        }).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "event", stuff: { a: "b" })
    end

    it "sends a POST request as json using json headers" do
      client = Customerio::Client.new("SITE_ID", "API_KEY", json: true)
      data = { type: "socks", price: "13.99" }
      body = { name: "purchase", data: data }

      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json(body),
             headers: {'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", data)
    end

    it "allows sending of a timestamp" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json({
          name: "purchase",
          data: {
            type: "socks",
            price: "13.99",
            timestamp: 1561231234
          },
          timestamp: 1561231234
        })).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", type: "socks", price: "13.99", timestamp: 1561231234)
    end

    it "doesn't send timestamp if timestamp is in milliseconds" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json({
          name: "purchase",
          data: {
            type: "socks",
            price: "13.99",
            timestamp: 1561231234000
          }
        })).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", type: "socks", price: "13.99", timestamp: 1561231234000)
    end

    it "doesn't send timestamp if timestamp is a date" do
      date = Time.now

      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: {
          name: "purchase",
          data: {
            type: "socks",
            price: "13.99",
            timestamp: Time.now.to_s
          }
        }).
        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", type: "socks", price: "13.99", timestamp: date)
    end

    it "doesn't send timestamp if timestamp isn't an integer" do
      stub_request(:post, api_uri('/api/v1/customers/5/events')).
        with(body: json({
          name: "purchase",
          data: {
            type: "socks",
            price: "13.99",
            timestamp: "Hello world"
          }
        })).

        to_return(status: 200, body: "", headers: {})

      client.track(5, "purchase", type: "socks", price: "13.99", timestamp: "Hello world")
    end

    context "tracking an anonymous event" do
      it "sends a POST request to the customer.io's anonymous event API" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(body: json({ name: "purchase", data: {} })).
          to_return(status: 200, body: "", headers: {})

        client.anonymous_track("purchase")
      end

      it "sends any optional event attributes" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(body: json({
            name: "purchase",
            data: {
              type: "socks",
              price: "13.99"
            }
          })).
          to_return(status: 200, body: "", headers: {})

        client.anonymous_track("purchase", type: "socks", price: "13.99")
      end

      it "allows sending of a timestamp" do
        stub_request(:post, api_uri('/api/v1/events')).
          with(body: json({
            name: "purchase",
            data: {
              type: "socks",
              price: "13.99",
              timestamp: 1561231234
            },
            timestamp: 1561231234
          })).
          to_return(status: 200, body: "", headers: {})

        client.anonymous_track("purchase", type: "socks", price: "13.99", timestamp: 1561231234)
      end
    end
  end

  describe "#anonymous_track" do
    it "raises an error if POST doesn't return a 2xx response code" do
      stub_request(:post, api_uri('/api/v1/events')).
        with(body: json(name: "purchase", data: {})).
        to_return(status: 500, body: "", headers: {})

      lambda { client.anonymous_track("purchase") }.should raise_error(Customerio::InvalidResponse)
    end

    it "throws an error when event_name is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.anonymous_track(" ") }.should raise_error(Customerio::Client::ParamError, "event_name must be a non-empty string")
    end

    it "uses the site_id and api key for basic auth and sends the event name" do
      stub_request(:post, api_uri('/api/v1/events')).
        with(body: json(name: "purchase", data: {})).
        to_return(status: 200, body: "", headers: {})

      client.anonymous_track("purchase")
    end

    it "sends any optional event attributes" do
      stub_request(:post, api_uri('/api/v1/events')).
          with(body: {
            name: "purchase",
            data: {
              type: "socks",
              price: "27.99"
            },
          }).

        to_return(status: 200, body: "", headers: {})

      client.anonymous_track("purchase", type: "socks", price: "27.99")
    end

    it "allows sending of a timestamp" do
      stub_request(:post, api_uri('/api/v1/events')).
          with(body: json({
            name: "purchase",
            data: {
              type: "socks",
              price: "27.99",
              timestamp: 1561235678
            },
            timestamp: 1561235678
          })).

        to_return(status: 200, body: "", headers: {})

      client.anonymous_track("purchase", type: "socks", price: "27.99", timestamp: 1561235678)
    end

    context "too many arguments are passed" do
      it "throws an error" do
        lambda { client.anonymous_track("purchase", "text", type: "socks", price: "27.99") }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#devices" do
    it "allows for the creation of a new device" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

      client.add_device(5, "androidDeviceID", "ios", {last_used: 1561235678})
      client.add_device(5, "iosDeviceID", "android")
    end
    it "requires a valid customer_id when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.add_device("", "ios", "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(nil, "ios", "myDeviceID", {last_used: 1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid token when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.add_device(5, "", "ios") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(5, nil, "ios", {last_used: 1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid platform when creating" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.add_device(5, "token", "") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.add_device(5, "toke", nil, {last_used: 1561235678}) }.should raise_error(Customerio::Client::ParamError)
    end
    it "accepts a nil data param" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

        client.add_device(5, "ios", "myDeviceID", nil)
    end
    it "fails on invalid data param" do
      stub_request(:put, api_uri('/api/v1/customers/5/devices')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.add_device(5, "ios", "myDeviceID", 1000) }.should raise_error(Customerio::Client::ParamError)
    end
    it "supports deletion of devices by token" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(status: 200, body: "", headers: {})

      client.delete_device(5, "myDeviceID")
    end
    it "requires a valid customer_id when deleting" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.delete_device("", "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.delete_device(nil, "myDeviceID") }.should raise_error(Customerio::Client::ParamError)
    end
    it "requires a valid device_id when deleting" do
      stub_request(:delete, api_uri('/api/v1/customers/5/devices/myDeviceID')).
        to_return(status: 200, body: "", headers: {})

       lambda { client.delete_device(5, "") }.should raise_error(Customerio::Client::ParamError)
       lambda { client.delete_device(5, nil) }.should raise_error(Customerio::Client::ParamError)
    end
  end

  describe "#region" do
    it "sends a GET request to the customer.io's region API" do
      stub_request(:get, api_uri('/api/v1/accounts/region')).
        to_return(status: 200, body: { region: "eu" }.to_json, headers: {})

      expect(client.region).to eq("region" => "eu")
    end

    it "throws an error when customer_id is missing" do
      stub_request(:put, /track.customer.io/)
        .to_return(status: 200, body: "", headers: {})

      lambda { client.suppress(" ") }.should raise_error(Customerio::Client::ParamError, "customer_id must be a non-empty string")
    end
  end
end
