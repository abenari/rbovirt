require "#{File.dirname(__FILE__)}/../spec_helper"

describe OVIRT, "API" do

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

  before(:all) do
    user, password, url = endpoint
    @client = ::OVIRT::Client.new(user, password, url)
  end

  after(:all) do
  end

  context 'basic api and listing' do
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

end
