require "#{File.dirname(__FILE__)}/../spec_helper"

describe "VM Life cycle" do

  before(:all) do
   user="admin@internal"
    password="123123"
    hostname = "covirt.sat.lab.tlv.redhat.com"
    port = "8080"
    url = "http://#{hostname}:#{port}/api"
    @blank_template_id = "00000000-0000-0000-0000-000000000000"
    @client = ::OVIRT::Client.new(user, password, url)
  end

  context 'basic vm and templates operations' do

    before(:all) do
      name = 'vm-'+Time.now.to_i.to_s
      @vm = @client.create_vm(:name => name)
      @client.add_volume(@vm.id)
      @client.add_interface(@vm.id)
      while @client.vm(@vm.id).status !~ /down/i do
      end
    end

    after(:all) do
      @client.destroy_vm(@vm.id)
    end

    it "test_should_create_template" do
      template_name = "test_template"
      template = @client.create_template(:vm => @vm.id, :name => template_name, :description => "test_template")
      template.class.to_s.should eql("OVIRT::Template")
      while @client.vm(@vm.id).status !~ /down/i do
      end
      @client.destroy_template(template.id)
    end

    it "test_should_return_a_template" do
      @client.template(@blank_template_id).id.should eql(@blank_template_id)
    end

    it "test_should_return_a_vm" do
      @client.vm(@vm.id).id.should eql(@vm.id)
    end

    it "test_should_start_and_stop_vm" do
      @client.vm_action(@vm.id, :start)
      @client.vm_action(@vm.id, :shutdown)
    end

    it "test_should_destroy_vm" do
      name = 'd-'+Time.now.to_i.to_s
      vm = @client.create_vm(:name => name)
      @client.destroy_vm(vm.id)
    end

    it "test_should_update_vm" do
      name = 'u-'+Time.now.to_i.to_s
      @client.update_vm(:id => @vm.id, :name=> name)
    end

    it "test_should_create_a_vm" do
      name = 'c-'+Time.now.to_i.to_s
      vm = @client.create_vm(:name => name)
      vm.class.to_s.should eql("OVIRT::VM")
      @client.destroy_vm(vm.id)
    end
  end
end