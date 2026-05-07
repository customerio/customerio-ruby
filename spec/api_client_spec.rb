require 'spec_helper'
require 'json'
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
    JSON.generate(data)
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

  describe "#send_sms" do
    it "sends a POST request to the /api/send/sms path" do
      req = Customerio::SendSMSRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/sms'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_sms(req).should eq({ "delivery_id" => 1 })
    end

    it "handles validation failures (400)" do
      req = Customerio::SendSMSRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/send/sms'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.send_sms(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::SendSMSRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/sms'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.send_sms(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end
  end

  describe "#send_inbox_message" do
    it "sends a POST request to the /api/send/inbox_message path" do
      req = Customerio::SendInboxMessageRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/inbox_message'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_inbox_message(req).should eq({ "delivery_id" => 1 })
    end

    it "handles validation failures (400)" do
      req = Customerio::SendInboxMessageRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/send/inbox_message'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.send_inbox_message(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::SendInboxMessageRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/inbox_message'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.send_inbox_message(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end
  end

  describe "#send_in_app" do
    it "sends a POST request to the /api/send/in_app path" do
      req = Customerio::SendInAppRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/in_app'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json, headers: {})

      client.send_in_app(req).should eq({ "delivery_id" => 1 })
    end

    it "handles validation failures (400)" do
      req = Customerio::SendInAppRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/send/in_app'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.send_in_app(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::SendInAppRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/in_app'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.send_in_app(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end
  end

  describe "#trigger_broadcast" do
    it "sends a POST request to the broadcast triggers path" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
        data: { headline: "Test" },
        recipients: { segment: { id: 7 } },
      )

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { trigger_id: "abc123" }.to_json, headers: {})

      client.trigger_broadcast(req).should eq({ "trigger_id" => "abc123" })
    end

    it "sends with email list audience" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
        emails: ["a@example.com", "b@example.com"],
        email_add_duplicates: false,
        email_ignore_missing: true,
      )

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { trigger_id: "abc123" }.to_json, headers: {})

      client.trigger_broadcast(req).should eq({ "trigger_id" => "abc123" })
    end

    it "sends with id list audience" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
        ids: [1, 2, 3],
        id_ignore_missing: true,
      )

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { trigger_id: "abc123" }.to_json, headers: {})

      client.trigger_broadcast(req).should eq({ "trigger_id" => "abc123" })
    end

    it "sends with data_file_url audience" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
        data_file_url: "https://example.com/data.json",
      )

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: { trigger_id: "abc123" }.to_json, headers: {})

      client.trigger_broadcast(req).should eq({ "trigger_id" => "abc123" })
    end

    it "raises an error when broadcast_id is missing" do
      lambda {
        Customerio::TriggerBroadcastRequest.new(data: { headline: "Test" })
      }.should raise_error(ArgumentError, "broadcast_id is required")
    end

    it "raises an error when broadcast_id is not an integer" do
      lambda {
        Customerio::TriggerBroadcastRequest.new(broadcast_id: "12")
      }.should raise_error(ArgumentError, "broadcast_id must be an integer")
    end

    it "raises an error when multiple audience fields are provided" do
      lambda {
        Customerio::TriggerBroadcastRequest.new(
          broadcast_id: 12,
          emails: ["a@example.com"],
          ids: [1, 2],
        )
      }.should raise_error(ArgumentError, /only one of/)
    end

    it "raises an error when request is not a TriggerBroadcastRequest" do
      lambda {
        client.trigger_broadcast("not a request")
      }.should raise_error(ArgumentError, /must be an instance of/)
    end

    it "handles validation failures (400)" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
        emails: ["a@example.com"],
      )

      err_json = { meta: { error: "example error" } }.to_json

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: err_json, headers: {})

      lambda { client.trigger_broadcast(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "example error"
          error.code.should eq "400"
        }
      )
    end

    it "handles other failures (5xx)" do
      req = Customerio::TriggerBroadcastRequest.new(
        broadcast_id: 12,
      )

      stub_request(:post, api_uri('/v1/campaigns/12/triggers'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 500, body: "Server unavailable", headers: {})

      lambda { client.trigger_broadcast(req) }.should(
        raise_error(Customerio::InvalidResponse) { |error|
          error.message.should eq "Server unavailable"
          error.code.should eq "500"
        }
      )
    end
  end
end
