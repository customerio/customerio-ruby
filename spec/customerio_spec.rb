require 'spec_helper'

describe Customerio do

  describe "Configuring Customerio" do
    it "should use the configuration opbject" do
      Customerio.configuration.class.should eql(Customerio::Configuration)
    end

    it "by config object" do
      Customerio.configure do |config|
        config.api_key = "API_KEY"
        config.site_id = "SITE_ID"
      end

      Customerio.configuration.api_key.should eql("API_KEY")
      Customerio.configuration.site_id.should eql("SITE_ID")
    end

  end

end

