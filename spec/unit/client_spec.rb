require "#{File.dirname(__FILE__)}/../spec_helper"

describe OVIRT::Client do
  context 'client initialization' do
    it 'should accept no option' do
      OVIRT::Client::new('mockuser','mockpass','http://example.com/api')
    end

    it 'should accept no datacenter_id in options' do
      OVIRT::Client::new('mockuser','mockpass','http://example.com/api', :datacenter_id => '123123')
    end

    it 'should support backward compatibility' do
      OVIRT::Client::new('mockuser','mockpass','http://example.com/api', '123123', '123123', false)
    end

    it 'should support options hash in 4th parameter' do
      OVIRT::Client::new('mockuser','mockpass','http://example.com/api',
                         {:datacenter_id => '123123',
                          :cluster_id    => '123123',
                          :filtered_api  => false,
                          :ca_cert_file  => 'ca_cert.pem'})
    end
  end

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
