require 'spec_helper'
require 'multi_json'
require 'base64'

describe Customerio::BaseClient do
  let(:base_uri) { "https://test.customer.io" }

  let(:site_id) { "SITE_ID" }
  let(:api_key) { "API_KEY" }
  let(:track_client) { Customerio::BaseClient.new({ site_id: site_id, api_key: api_key }, { base_uri: base_uri }) }

  let(:app_key) { "APP_KEY" }
  let(:api_client) { Customerio::BaseClient.new({ app_key: app_key }, { base_uri: base_uri }) }

  def api_uri(path)
    "#{base_uri}#{path}"
  end

  def track_client_request_headers
    token = Base64.strict_encode64("#{site_id}:#{api_key}")
    { 'Authorization': "Basic #{token}", 'Content-Type': 'application/json' }
  end

  def api_client_request_headers
    { 'Authorization': "Bearer #{app_key}", 'Content-Type': 'application/json' }
  end

  describe "with a site ID and API key" do
    it "uses the correct basic auth" do
      stub_request(:put, api_uri('/some/path')).
        with(headers: track_client_request_headers).
        to_return(status: 200, body: "", headers: {})

      track_client.request(:put, '/some/path', "")
    end

    it "escapes URLs" do
      client = Customerio::BaseClient.new({ site_id: site_id, api_key: api_key }, { base_uri: base_uri })

      stub_request(:put, api_uri('/some/path%20')).
        with(headers: track_client_request_headers).
        to_return(status: 200, body: "", headers: {})

      track_client.request(:put, '/some/path ', "")
    end
  end

  describe "with an app key" do
    it "uses the correct bearer token" do
      stub_request(:put, api_uri('/some/path')).
        with(headers: api_client_request_headers).
        to_return(status: 200, body: "", headers: {})

      api_client.request(:put, '/some/path', "")
    end

    it "escapes URLs" do
      stub_request(:put, api_uri('/some/path%20')).
        with(headers: api_client_request_headers).
        to_return(status: 200, body: "", headers: {})

      api_client.request(:put, '/some/path ', "")
    end
  end

  describe "#verify_response" do
    it "throws an error when the response isn't between 200 and 300" do
      stub_request(:put, api_uri('/some/path')).
        with(headers: api_client_request_headers).
        to_return(status: 400, body: "", headers: {})

      lambda { api_client.request_and_verify_response(:put, '/some/path', "") }.should(
        raise_error(Customerio::BaseClient::InvalidResponse)
      )
    end

    it "returns the response when the status is 200" do
      stub_request(:put, api_uri('/some/path')).
        with(headers: api_client_request_headers).
        to_return(status: 200, body: "Test", headers: {})

      api_client.request_and_verify_response(:put, '/some/path', "").body.should eq("Test")
    end
  end
end
