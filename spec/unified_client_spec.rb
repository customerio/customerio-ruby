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

    it "uses an explicit region over the key" do
      expect(Customerio::UnifiedClient.new(eu_key, region: Customerio::Regions::US).region).to eq(Customerio::Regions::US)
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
      track = stub_request(:put, "http://track.test/api/v1/customers/1").to_return(status: 200, body: "")
      api = stub_request(:post, "http://api.test/v1/send/email").to_return(status: 200, body: "{}")

      client = Customerio::UnifiedClient.new(us_key, track_url: "http://track.test", api_url: "http://api.test")
      client.identify(id: "1")
      client.send_email(email_request)

      expect(track).to have_been_requested
      expect(api).to have_been_requested
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

    it "raise KeyCapabilityError from api_client" do
      expect { client.api_client }
        .to raise_error(Customerio::KeyCapabilityError, /public keys \(pk_\).*secret key \(sk_\)/)
    end
  end

  describe "server refusals" do
    let(:client) { Customerio::UnifiedClient.new(us_key) }

    [401, 403].each do |status|
      it "re-raises a #{status} from the Track API as KeyCapabilityError" do
        stub_request(:put, "https://track.customer.io/api/v1/customers/1").to_return(status: status, body: "forbidden")

        expect { client.identify(id: "1") }.to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:track)
          expect(error.code).to eq(status.to_s)
          expect(error.message).to eq("This key can't send tracking data (#{status}): forbidden")
          expect(error.cause).to be_a(Customerio::InvalidResponse)
        }
      end

      it "re-raises a #{status} from the App API as KeyCapabilityError" do
        stub_request(:post, "https://api.customer.io/v1/send/email").to_return(status: status, body: "nope")

        expect { client.send_email(email_request) }.to raise_error(Customerio::KeyCapabilityError) { |error|
          expect(error.capability).to eq(:transactional)
          expect(error.code).to eq(status.to_s)
          expect(error.message).to eq("This key can't send transactional messages (#{status}): nope")
          expect(error.cause).to be_a(Customerio::InvalidResponse)
        }
      end
    end

    it "leaves other errors alone" do
      stub_request(:put, "https://track.customer.io/api/v1/customers/1").to_return(status: 500, body: "boom")

      expect { client.identify(id: "1") }.to raise_error(Customerio::InvalidResponse)
    end
  end
end
