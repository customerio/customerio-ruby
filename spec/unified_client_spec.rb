require 'spec_helper'
require 'json'

describe Customerio::UnifiedClient do
  let(:us_key) { "sk_us_0123456789ABCDEFGHIJKLMNOPQRSTUV_000000" }
  let(:eu_key) { "sk_eu_0123456789ABCDEFGHIJKLMNOPQRSTUV_000000" }
  let(:public_key) { "pk_us_0123456789ABCDEFGHIJKLMNOPQRSTUV_000000" }
  let(:legacy_key) { "abc123" }

  let(:email_request) do
    Customerio::SendEmailRequest.new(to: "a@example.com", identifiers: { id: "user_123" }, transactional_message_id: 5)
  end

  def bearer(key)
    { 'Authorization' => "Bearer #{key}" }
  end

  it "requires an api key" do
    expect { Customerio::UnifiedClient.new("") }.to raise_error(ArgumentError, "api_key is required")
    expect { Customerio::UnifiedClient.new(nil) }.to raise_error(ArgumentError, "api_key is required")
  end

  it "raises an error when an incorrect region is passed in" do
    expect {
      Customerio::UnifiedClient.new(us_key, region: :au)
    }.to raise_error(ArgumentError, /region must be an instance of Customerio::Regions::Region/)
  end

  describe "region" do
    it "comes from the key" do
      expect(Customerio::UnifiedClient.new(us_key).region).to eq(Customerio::Regions::US)
      expect(Customerio::UnifiedClient.new(eu_key).region).to eq(Customerio::Regions::EU)
      expect(Customerio::UnifiedClient.new(public_key).region).to eq(Customerio::Regions::US)
    end

    it "accepts an explicit region that matches the key" do
      expect(Customerio::UnifiedClient.new(eu_key, region: Customerio::Regions::EU).region).to eq(Customerio::Regions::EU)
    end

    it "raises when an explicit region disagrees with the key" do
      expect {
        Customerio::UnifiedClient.new(eu_key, region: Customerio::Regions::US)
      }.to raise_error(ArgumentError, "region us does not match the eu region of this key")
      expect {
        Customerio::UnifiedClient.new(public_key, region: Customerio::Regions::EU)
      }.to raise_error(ArgumentError, "region eu does not match the us region of this key")
    end

    it "accepts a custom region with a prefixed key" do
      custom = Customerio::Regions::Region.new("https://track.proxy.test", "https://api.proxy.test")
      expect(Customerio::UnifiedClient.new(eu_key, region: custom).region).to eq(custom)

      stub = stub_request(:put, "https://track.proxy.test/api/v1/customers/user_123")
        .with(headers: bearer(eu_key))
        .to_return(status: 200, body: "")

      Customerio::UnifiedClient.new(eu_key, region: custom).identify(id: "user_123")
      expect(stub).to have_been_requested
    end

    it "treats an unknown prefix as a legacy key" do
      client = Customerio::UnifiedClient.new("xx_us_abc", region: Customerio::Regions::EU)
      expect(client.region).to eq(Customerio::Regions::EU)

      stub = stub_request(:post, "https://api-eu.customer.io/v1/send/email")
        .with(headers: bearer("xx_us_abc"))
        .to_return(status: 200, body: "{}")

      client.send_email(email_request)
      expect(stub).to have_been_requested
    end

    it "keeps the region option and US default for legacy keys" do
      expect(Customerio::UnifiedClient.new(legacy_key).region).to eq(Customerio::Regions::US)
      expect(Customerio::UnifiedClient.new(legacy_key, region: Customerio::Regions::EU).region).to eq(Customerio::Regions::EU)
    end

    it "ignores whitespace around the key" do
      client = Customerio::UnifiedClient.new("  #{eu_key}\n")
      expect(client.region).to eq(Customerio::Regions::EU)

      stub = stub_request(:put, "https://track-eu.customer.io/api/v1/customers/user_123")
        .with(headers: bearer(eu_key))
        .to_return(status: 200, body: "", headers: {})

      client.identify(id: "user_123", email: "a@example.com")
      expect(stub).to have_been_requested
    end
  end

  describe "tracking" do
    let(:client) { Customerio::UnifiedClient.new(us_key) }

    it "sends identify to the Track API with Bearer" do
      stub = stub_request(:put, "https://track.customer.io/api/v1/customers/user_123")
        .with(headers: bearer(us_key), body: { id: "user_123", email: "a@example.com" })
        .to_return(status: 200, body: "")

      client.identify(id: "user_123", email: "a@example.com")
      expect(stub).to have_been_requested
    end

    it "sends track, track_anonymous and pageview to the Track API with Bearer" do
      customer_events = stub_request(:post, "https://track.customer.io/api/v1/customers/user_123/events")
        .with(headers: bearer(us_key))
        .to_return(status: 200, body: "")
      anonymous_events = stub_request(:post, "https://track.customer.io/api/v1/events")
        .with(headers: bearer(us_key), body: { name: "viewed", data: {}, anonymous_id: "anon_1" })
        .to_return(status: 200, body: "")

      client.track("user_123", "order_completed")
      client.pageview("user_123", "/pricing")
      client.track_anonymous("anon_1", "viewed")

      expect(customer_events).to have_been_requested.twice
      expect(anonymous_events).to have_been_requested
    end

    it "lets a public key track" do
      stub = stub_request(:put, "https://track.customer.io/api/v1/customers/user_123")
        .with(headers: bearer(public_key))
        .to_return(status: 200, body: "")

      Customerio::UnifiedClient.new(public_key).identify(id: "user_123")
      expect(stub).to have_been_requested
    end
  end

  describe "transactional" do
    let(:client) { Customerio::UnifiedClient.new(us_key) }

    it "sends email to the App API with Bearer" do
      stub_request(:post, "https://api.customer.io/v1/send/email")
        .with(headers: bearer(us_key), body: email_request.message)
        .to_return(status: 200, body: { delivery_id: 1 }.to_json)

      expect(client.send_email(email_request)).to eq({ "delivery_id" => 1 })
    end

    {
      send_push: [Customerio::SendPushRequest, { transactional_message_id: 1, identifiers: { id: "c1" } }, "/v1/send/push"],
      send_sms: [Customerio::SendSMSRequest, { transactional_message_id: 1, identifiers: { id: "c1" } }, "/v1/send/sms"],
      send_whatsapp: [Customerio::SendWhatsAppRequest, { transactional_message_id: 1, identifiers: { id: "c1" } }, "/v1/send/whatsapp"],
      send_inbox_message: [Customerio::SendInboxMessageRequest, { transactional_message_id: 1, identifiers: { id: "c1" } }, "/v1/send/inbox_message"],
      send_in_app: [Customerio::SendInAppRequest, { transactional_message_id: 1, identifiers: { id: "c1" } }, "/v1/send/in_app"],
      trigger_broadcast: [Customerio::TriggerBroadcastRequest, { broadcast_id: 12 }, "/v1/campaigns/12/triggers"]
    }.each do |method, (request_class, opts, path)|
      it "sends #{method} to the App API with Bearer" do
        stub = stub_request(:post, "https://api.customer.io#{path}")
          .with(headers: bearer(us_key))
          .to_return(status: 200, body: { delivery_id: 1 }.to_json)

        client.public_send(method, request_class.new(opts))
        expect(stub).to have_been_requested
      end
    end

    it "uses EU hosts for an sk_eu_ key" do
      track = stub_request(:put, "https://track-eu.customer.io/api/v1/customers/user_123").to_return(status: 200, body: "")
      api = stub_request(:post, "https://api-eu.customer.io/v1/send/email").to_return(status: 200, body: "{}")

      client = Customerio::UnifiedClient.new(eu_key)
      client.identify(id: "user_123")
      client.send_email(email_request)

      expect(track).to have_been_requested
      expect(api).to have_been_requested
    end

    it "lets custom URLs override the region hosts" do
      track = stub_request(:put, "https://track.test/api/v1/customers/1").to_return(status: 200, body: "")
      api = stub_request(:post, "https://api.test/v1/send/email").to_return(status: 200, body: "{}")

      client = Customerio::UnifiedClient.new(us_key, track_url: "https://track.test", api_url: "https://api.test")
      client.identify(id: "1")
      client.send_email(email_request)

      expect(track).to have_been_requested
      expect(api).to have_been_requested
    end
  end

  describe "urls" do
    it "refuses a track_url or api_url that isn't https" do
      expect { Customerio::UnifiedClient.new(us_key, track_url: "http://track.test") }
        .to raise_error(ArgumentError, "track_url must start with https://")
      expect { Customerio::UnifiedClient.new(us_key, api_url: "http://api.test") }
        .to raise_error(ArgumentError, "api_url must start with https://")
    end

    it "refuses a URL it can't parse" do
      expect { Customerio::UnifiedClient.new(us_key, api_url: "https://api test") }
        .to raise_error(ArgumentError, "api_url is not a valid URL: https://api test")
      expect { Customerio::UnifiedClient.new(us_key, track_url: "https://") }
        .to raise_error(ArgumentError, "track_url is not a valid URL: https://")
    end

    it "refuses a custom region that isn't https" do
      custom = Customerio::Regions::Region.new("https://track.proxy.test", "http://api.proxy.test")

      expect { Customerio::UnifiedClient.new(us_key, region: custom) }
        .to raise_error(ArgumentError, "region api_url must start with https://")
      expect { Customerio::UnifiedClient.new(legacy_key, region: custom) }
        .to raise_error(ArgumentError, "region api_url must start with https://")
    end
  end

  describe "public keys" do
    let(:client) { Customerio::UnifiedClient.new(public_key) }

    it "raise KeyCapabilityError before sending a transactional message" do
      expect { client.send_email(email_request) }.to raise_error(Customerio::KeyCapabilityError) { |error|
        expect(error.capability).to eq(:transactional)
        expect(error.code).to be_nil
      }
      expect(a_request(:any, /customer\.io/)).not_to have_been_made
    end

    it "raise KeyCapabilityError before triggering a broadcast" do
      expect { client.trigger_broadcast(Customerio::TriggerBroadcastRequest.new(broadcast_id: 12)) }
        .to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:broadcast)
          expect(error.code).to be_nil
        }
      expect(a_request(:any, /customer\.io/)).not_to have_been_made
    end

    it "raise KeyCapabilityError from api_client" do
      expect { client.api_client }
        .to raise_error(Customerio::KeyCapabilityError, /public keys \(pk_\).*secret key \(sk_\)/)
    end
  end

  describe "server refusals" do
    let(:client) { Customerio::UnifiedClient.new(us_key) }

    [401, 403].each do |status|
      it "re-raises a #{status} from the Track API as KeyCapabilityError" do
        stub_request(:put, "https://track.customer.io/api/v1/customers/1").to_return(status: status, body: '{"meta":{"error":"forbidden"}}')

        expect { client.identify(id: "1") }.to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:track)
          expect(error.code).to eq(status)
          expect(error.message).to eq("The server refused this request to send tracking data (#{status}): forbidden. Check the key type, its IP restrictions and the workspace status.")
          expect(error.cause).to be_a(Customerio::InvalidResponse)
        }
      end

      it "re-raises a #{status} from the App API as KeyCapabilityError" do
        stub_request(:post, "https://api.customer.io/v1/send/email").to_return(status: status, body: '{"errors":[{"detail":"unauthorized","status":"401"}]}')

        expect { client.send_email(email_request) }.to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:transactional)
          expect(error.code).to eq(status)
          expect(error.message).to eq("The server refused this request to send transactional messages (#{status}): unauthorized. Check the key type, its IP restrictions and the workspace status.")
          expect(error.cause).to be_a(Customerio::InvalidResponse)
        }
      end
    end

    it "re-raises a 403 from a broadcast trigger as a broadcast refusal" do
      stub_request(:post, "https://api.customer.io/v1/campaigns/12/triggers").to_return(status: 403, body: '{"errors":[{"detail":"unauthorized","status":"401"}]}')

      expect { client.trigger_broadcast(Customerio::TriggerBroadcastRequest.new(broadcast_id: 12)) }
        .to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:broadcast)
          expect(error.code).to eq(403)
          expect(error.message).to eq("The server refused this request to trigger broadcasts (403): unauthorized. Check the key type, its IP restrictions and the workspace status.")
        }
    end

    ["nope", '["nope"]', '"nope"', '{"errors":"nope"}'].each do |body|
      it "shows the body #{body} as it came" do
        stub_request(:put, "https://track.customer.io/api/v1/customers/1").to_return(status: 401, body: body)

        expect { client.identify(id: "1") }.to raise_error(
          Customerio::KeyCapabilityError,
          "The server refused this request to send tracking data (401): #{body}. Check the key type, its IP restrictions and the workspace status."
        )
      end
    end

    it "leaves other errors alone" do
      stub_request(:put, "https://track.customer.io/api/v1/customers/1").to_return(status: 500, body: "boom")

      expect { client.identify(id: "1") }.to raise_error(Customerio::InvalidResponse)
    end
  end
end
