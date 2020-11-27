require 'spec_helper'
require 'multi_json'
require 'base64'

describe Customerio::APIClient do
  let(:app_key) { "appkey" }

  let(:client)   { Customerio::APIClient.new(app_key) }
  let(:response) { double("Response", code: 200) }

  def api_uri(path)
    "https://api.customer.io#{path}"
  end

  def request_headers
    { 'Authorization': "Bearer #{app_key}", 'Content-Type': 'application/json' }
  end

  def json(data)
    MultiJson.dump(data)
  end

  describe "#send_email" do
    it "sends a POST request to the /api/send/email path" do
      payload = {
        customer_id: 'c1',
        transactional_message_id: 1,
      }

      stub_request(:post, api_uri('/v1/api/send/email'))
        .with(headers: request_headers, body: payload)
        .to_return(status: 200, body: "", headers: {})

      client.send_email(payload)
    end
  end
end
