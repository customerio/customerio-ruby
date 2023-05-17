require 'spec_helper'
require 'multi_json'
require 'base64'
require 'tempfile'

describe Customerio::APIClient do
  let(:app_key) { "appkey" }

  let(:client) { Customerio::APIClient.new(app_key) }
  let(:response) { double("Response", code: 200) }

  def api_uri(path)
    "https://api.customer.io#{path}"
  end

  def request_headers
    { 'Authorization': "Bearer #{app_key}", 'Content-Type': 'application/json', 'User-Agent': 'Customer.io Ruby Client/' + Customerio::VERSION }
  end

  def json(data)
    MultiJson.dump(data)
  end

  it "the base client is initialised with the correct values when no region is passed in" do
    app_key = "appkey"

    expect(Customerio::BaseClient).to(
      receive(:new)
        .with(
          { app_key: app_key },
          {
            region: Customerio::Regions::US,
            url: Customerio::Regions::US.api_url
          }
        )
    )

    client = Customerio::APIClient.new(app_key)
  end

  it "raises an error when an incorrect region is passed in" do
    expect {
      Customerio::APIClient.new("appkey", region: :au)
    }.to raise_error /region must be an instance of Customerio::Regions::Region/
  end

  [Customerio::Regions::US, Customerio::Regions::EU].each do |region|
    it "the base client is initialised with the correct values when the region \"#{region}\" is passed in" do
      app_key = "appkey"

      expect(Customerio::BaseClient).to(
        receive(:new)
          .with(
            { app_key: app_key },
            {
              region: region,
              url: region.api_url
            }
          )
      )

      client = Customerio::APIClient.new(app_key, { region: region })
    end
  end

  describe "#send_email" do
    it "sends a POST request to the /api/send/email path" do
      req = Customerio::SendEmailRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_email(req).should eq({ "delivery_id" => 1 })
    end

    it "handles validation failures (400)" do
      req = Customerio::SendEmailRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.send_email(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::SendEmailRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.send_email(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end

    it "allows attaching file content without encoding" do
      content = 'sample content'

      req = Customerio::SendEmailRequest.new(
        customer_id: 'c1',
        transactional_message_id: 1,
      )

      req.attach('test', content, encode: false)
      req.message[:attachments]['test'].should eq content

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_email(req)
    end

    it "allows attaching files with encoding (default)" do
      content = 'sample content'

      req = Customerio::SendEmailRequest.new(
        customer_id: 'c1',
        transactional_message_id: 1,
      )

      req.attach('test', content)
      req.message[:attachments]['test'].should eq Base64.strict_encode64(content)

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_email(req)
    end

    it "raises error when attaching the same key again" do
      req = Customerio::SendEmailRequest.new(
        customer_id: 'c1',
        transactional_message_id: 1,
      )

      req.attach('test', 'test-content')

      lambda { req.attach('test', '') }.should raise_error(/attachment test already exists/)
      req.message[:attachments].should eq({ "test" => Base64.strict_encode64("test-content") })
    end
  end

  describe "#send_push" do
    it "sends a POST request to the /api/send/push path" do
      req = Customerio::SendPushRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/push'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_push(req).should eq({ "delivery_id" => 1 })
    end

    it "handles validation failures (400)" do
      req = Customerio::SendPushRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/send/push'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.send_push(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::SendPushRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/push'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.send_push(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end

    it "sets custom_device correctly if device present in req" do
      req = Customerio::SendPushRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
        device: {
          platform: 'ios',
          token: 'sample-token',
        }
      )

      req.message[:custom_device].should eq({
        platform: 'ios',
        token: 'sample-token',
      })

      stub_request(:post, api_uri('/v1/send/push'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 2 }.to_json, headers: {})

      client.send_push(req).should eq({ "delivery_id" => 2 })
    end
  end

  describe '#trigger_broadcast' do
    it "sends a POST request to the customer.io's broadcast API" do
      payload = {
        data: { name: 'foo' },
        recipients: {
          segment: { id: 7 }
        }
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      expect(client.trigger_broadcast(req)).to eq({ 'delivery_id' => 1 })
    end

    it "handles validation failures (400)" do
      payload = {
        data: { name: 'foo' },
        emails: ['foo', 'bar'],
        email_ignore_missing: true,
        email_add_duplicates: true
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.trigger_broadcast(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      payload = {
        data: { name: 'foo' },
        emails: ['foo', 'bar'],
        email_ignore_missing: true,
        email_add_duplicates: true
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.trigger_broadcast(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end

    it 'supports campaign triggers based on email fields' do
      payload = {
        data: { name: 'foo' },
        emails: ['foo', 'bar'],
        email_ignore_missing: true,
        email_add_duplicates: true
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})


      expect(client.trigger_broadcast(req)).to eq({ 'delivery_id' => 1 })
    end

    it 'supports campaign triggers based on id fields' do
      payload = {
        data: { name: 'foo' },
        ids: [1, 2, 3],
        id_ignore_missing: true
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      expect(client.trigger_broadcast(req)).to eq({ 'delivery_id' => 1 })
    end

    it 'supports campaign triggers based on per user data' do
      user_data = { id: 1, data: { name: 'foo' } }
      payload = {
        data: { name: 'foo' },
        per_user_data: [user_data]
      }
      req = Customerio::TriggerBroadcastRequest.new(broadcast_id: 1, payload: payload)

      stub_request(:post, api_uri('/v1/campaigns/1/triggers'))
        .with(headers: request_headers, body: req.payload)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      expect(client.trigger_broadcast(req)).to eq({ 'delivery_id' => 1 })
    end
  end
end
