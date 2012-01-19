require 'helper'

class TestRbovirt < Test::Unit::TestCase

  def setup
    user="admin@internal"
    password="123123"
    hostname = "ovirt.sat.lab.tlv.redhat.com"
    port = "8080"
    url = "http://#{hostname}:#{port}/api"
    @blank_template_id = "00000000-0000-0000-0000-000000000000"
    @client = ::OVIRT::Client.new(user, password, url)
  end

  def test_should_return_a_version
    assert @client.api_version
  end

  def test_should_return_datacenters
    assert @client.datacenters
  end

  def test_should_return_clusters
    assert @client.clusters
  end

  def test_should_return_templates
    assert @client.templates
  end

  def test_should_create_template
    name = 't'+Time.now.to_i.to_s
    params = {}
    params[:name] = name
    params[:cluster_name] = "test"
    vm = @client.create_vm("Blank",params)

    @client.add_volume(vm.id)
    @client.add_interface(vm.id)
    while @client.vm(vm.id).status !~ /down/i do
    end
    template_name = "test_template"
    assert template = @client.create_template(vm.id, :name => template_name, :description => "test_template")
    while @client.vm(vm.id).status !~ /down/i do
    end
    assert @client.destroy_template(template.id)
    @client.destroy_vm(vm.id)
  end

  def test_should_return_a_template
    assert @client.template(@blank_template_id)
  end


  def test_should_return_vms
    assert @client.vms
  end

  def test_should_return_a_vm
    name = 'a'+Time.now.to_i.to_s
    params = {}
    params[:name] = name
    params[:cluster_name] = "test"
    vm = @client.create_vm("Blank",params)
    assert @client.vm(vm.id)
    @client.destroy_vm(vm.id)
  end

  def test_should_start_vm
    name = 'r'+Time.now.to_i.to_s
    params = {}
    params[:name] = name
    params[:cluster_name] = "test"
    vm = @client.create_vm("Blank",params)
    @client.add_volume(vm.id)
    @client.add_interface(vm.id)
    while @client.vm(vm.id).status !~ /down/i do
    end  
    assert @client.vm_action(vm.id, :start)
    @client.vm_action(vm.id, :shutdown)
    while @client.vm(vm.id).status !~ /down/i do
    end
    @client.destroy_vm(vm.id)
  end

  def test_should_stop_vm

  end

  def test_should_destroy_vm
    name = 'd'+Time.now.to_i.to_s
    params = {}
    params[:name] = name
    params[:cluster_name] = "test"
    vm = @client.create_vm("Blank",params)
    assert @client.destroy_vm(vm.id)
  end

  def test_should_return_storage
    assert @client.storagedomains
  end

  def test_should_create_a_vm
    name = 'c'+Time.now.to_i.to_s
    params = {}
    params[:name] = name
    params[:cluster_name] = "test"
    assert vm = @client.create_vm("Blank",params)
    @client.destroy_vm(vm.id)
  end

end
