require "#{File.dirname(__FILE__)}/../spec_helper"

describe OVIRT::Client do

  context 'http comms' do
    before(:each) do
      @sut = OVIRT::Client::new('mockuser','mockpass','http://example.com/api')
    end
      
    it "should add Accept: headers" do
      headers = @sut.send(:http_headers)
      headers[:accept].should eql('application/xml')
    end

    it "should keep existing Accept: headers" do
      value = "application/xml; detail=disks; detail=nics; detail=hosts"
      headers = @sut.send(:http_headers, {:accept => value})
      headers[:accept].should eql(value)
    end
  end
end
