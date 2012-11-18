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

describe OVIRT, "Admin API" do

  before(:all) do
    user, password, url = endpoint
    @client = ::OVIRT::Client.new(user, password, url, nil, nil, false)
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
    user, password, url = endpoint
    @client = ::OVIRT::Client.new(user, password, url, nil, nil, support_user_level_api)
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