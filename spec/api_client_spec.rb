require 'spec_helper'
require 'multi_json'
require 'base64'
require 'tempfile'

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
      req = Customerio::SendEmailRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: "", headers: {})

      client.send_email(req)
    end

    it "handles failures" do
      req = Customerio::SendEmailRequest.new(
        identifiers: {
          id: 'c1',
        },
        transactional_message_id: 1,
      )

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 400, body: "", headers: {})

      lambda { client.send_email(req) }.should raise_error(Customerio::BaseClient::InvalidResponse)
    end

    it "allows attaching files by names" do
      content = 'sample content'

      file = Tempfile.new('example.txt')
      file.write(content)
      file.rewind # move the read counter back so the file can be read again
      File.stub(:open).and_return(file)

      req = Customerio::SendEmailRequest.new(
        customer_id: 'c1',
        transactional_message_id: 1,
      )

      req.attach('test', 'example.txt')
      req.message[:attachments]['test'].should eq Base64.strict_encode64(content)

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: "", headers: {})

      client.send_email(req)
    end

    it "allows attaching files by File objects" do
      content = 'sample content'

      file = Tempfile.new('example.txt')
      file.write(content)
      file.rewind # move the read counter back so the file can be read again
      File.stub(:open).and_return(file)

      req = Customerio::SendEmailRequest.new(
        customer_id: 'c1',
        transactional_message_id: 1,
      )

      req.attach('test', file)
      req.message[:attachments]['test'].should eq Base64.strict_encode64(content)

      stub_request(:post, api_uri('/v1/send/email'))
        .with(headers: request_headers, body: req.message)
        .to_return(status: 200, body: "", headers: {})

      client.send_email(req)
    end
  end
end
