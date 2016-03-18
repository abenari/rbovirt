require "#{File.dirname(__FILE__)}/../spec_helper"

shared_examples_for "API" do

  # This spec requires the API to be stable, so that projects using
  # OVIRT do not have to update their code if a new (minor)
  # version is released.
  #
  # API compatibility is only guaranteed for minor version changes;
  # New major versions may change the API and require code changes
  # in projects using this plugin.
  #
  # Because of the API stability guarantee, these spec's may only
  # be changed for new major releases.

  it "test_should_return_a_version" do
    @client.api_version.class.should eql(String)
  end

  it "test_should_return_datacenters" do
    @client.datacenters.class.should eql(Array)
  end

  it "test_should_return_clusters" do
    @client.clusters.class.should eql(Array)
  end

  it "test_should_return_templates" do
    @client.templates.class.should eql(Array)
  end

  it "test_should_return_vms" do
    @client.vms.class.should eql(Array)
  end

  it "test_should_return_storage" do
    @client.storagedomains.class.should eql(Array)
  end
end

describe OVIRT, "Https authentication" do
  context 'authenticate using the server ca certificate' do

    it "test_should_get_ca_certificate" do
      user, password, url, datacenter = endpoint
      ca_cert(url).class.should eql(String)
    end

    it "should_authenticate_with_ca_certificate" do
      user, password, url, datacenter = endpoint
      cert = ca_cert(url)
      store = OpenSSL::X509::Store.new().add_cert(
              OpenSSL::X509::Certificate.new(cert))

       client = ::OVIRT::Client.new(user, password, url, {:ca_cert_store => store})
       client.api_version.class.should eql(String)
    end
  end
end

describe OVIRT, "Persistent authentication" do
  context 'use persistent authentication' do

    it "test_request_with_persistent_authentication" do
      user, password, url, datacenter = endpoint
      cert = ca_cert(url)
      store = OpenSSL::X509::Store.new().add_cert(
              OpenSSL::X509::Certificate.new(cert))

      client = ::OVIRT::Client.new(user, password, url, {:ca_cert_store => store, :persistent_auth => true})
      client.api_version.class.should eql(String)
      client.persistent_auth.should eql(true)
      client.jsessionid.should_not be_nil

      # When performing a new request the jsessionid should remain the same
      orig_jsession_id = client.jsessionid
      client.datacenters.class.should eql(Array)
      client.jsessionid.should eql(orig_jsession_id)
    end
  end
end

describe OVIRT, "Admin API" do

  before(:all) do
    setup_client
  end

  after(:all) do
  end

  context 'basic admin api and listing' do
    it_behaves_like "API"

    it "test_should_return_hosts" do
      @client.hosts.class.should eql(Array)
    end
  end

end

describe OVIRT, "User API" do

  before(:all) do
    setup_client :filtered_api => support_user_level_api
  end

  after(:all) do
  end

  context 'basic user api and listing' do
    it_behaves_like "API"
    #User level API doesn't support returning hosts
    it "test_should_not_return_hosts" do
      if support_user_level_api
        expect {@client.hosts}.to raise_error
      end
    end
  end

end

describe OVIRT, "Operating systems API" do

  before(:all) do
    setup_client
  end

  context 'basic user api and listing' do
    it "exposes supported operating systems" do
      oses = @client.operating_systems
      oses.should_not be_empty
      os = oses.first
      os.id.should_not be_empty
      os.name.should_not be_empty
      os.description.should_not be_empty
    end
  end

end
