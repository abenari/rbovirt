require 'helper'

class TestRbovirt < Test::Unit::TestCase

  def setup
    user="admin@internal"
    password="123123"
    hostname = "ovirt.sat.lab.tlv.redhat.com"
    port = "8080"
    url = "http://#{hostname}:#{port}/api"
    datacenter = "default"
    @client = ::OVIRT::Client.new(user, password, url, datacenter)
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

  def test_should_return_a_template
    id = "123123"
    assert @client.template(id)
  end

  def test_should_create_template
    id = "123123"
    template_name = "test_123"
    assert @client.create_template(id, :name => template_name, :description => "test_template")
  end

  def test_should_destroy_template
    id = "123123"
    assert @client.destroy_template(id)
  end

  def test_should_return_vms
    assert @client.vms
  end

   def test_should_return_a_vm
     id = "123123"
     assert @client.vms(:id => id)
   end

  def test_should_start_vm
    id = "123123"
    assert @client.vm_action(id, :start)
  end

  def test_should_stop_vm
    assert @client.vm_action(id, :shutdown)
  end

  def test_should_destroy_vm(credentials, id)
    assert @client.vm_action(id, :delete)
  end

  def test_should_return_storage_domains
    assert @client.storagedomains
  end

  def test_should_create_vm
    template_id = "123123"
    name = Time.now.to_i.to_s
    params = {}
    params[:name] = name
    assert @client.create_vm(template_id, params)
  end

end
