require 'spec_helper'

describe Customerio::Configuration do

  it "Should initialize empty configuration" do
    lambda{Customerio::Configuration.new}.should_not raise_error
  end

  describe "Setting keys on config object" do
    let(:config) { Customerio::Configuration.new }

   it "should set api key" do
     config.api_key = "something_non_trivial"
     config.api_key.should eql("something_non_trivial")
   end

   it "should set site id" do
     config.site_id = "some_random_string"
     config.site_id.should eql("some_random_string")
   end

  end


end
