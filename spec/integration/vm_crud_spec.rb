require "#{File.dirname(__FILE__)}/../spec_helper"

shared_examples_for "Basic VM Life cycle" do

  before(:all) do
    name = 'vm-'+Time.now.to_i.to_s
    @cluster = @client.clusters.select{|c| c.name == cluster_name}.first.id
    @template_id = "00000000-0000-0000-0000-000000000000"
    @vm = @client.create_vm(:name => name, :template => @template_id, :cluster => @cluster)
    @client.add_volume(@vm.id)
    @client.add_interface(@vm.id, :network_name => network_name)
    while !@client.vm(@vm.id).ready? do
    end
  end

  after(:all) do
    @client.destroy_vm(@vm.id)
  end

  it "test_should_create_template" do
    template_name = "tmplt-"+Time.now.to_i.to_s
    template = @client.create_template(:vm => @vm.id, :name => template_name, :description => "test_template", :comment => "test_template")
    template.class.to_s.should eql("OVIRT::Template")
    while !@client.vm(@vm.id).ready? do
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
    while !@client.vm(@vm.id).running? do
    end
    @client.vm_action(@vm.id, :shutdown)
  end

  it "test_should_start_with_cloudinit" do
    hostname = "host-"+Time.now.to_i.to_s
    user_data={ :hostname => hostname }
    @client.vm_start_with_cloudinit(@vm.id, user_data)
    while !@client.vm(@vm.id).running? do
    end
    @client.vm_action(@vm.id, :shutdown)
  end

  it "test_should_set_vm_ticket" do
    while @client.vm(@vm.id).status.strip != 'down' do
    end
    @client.vm_action(@vm.id, :start)
    while !@client.vm(@vm.id).running? do
    end
    @client.set_ticket(@vm.id)
    @client.vm_action(@vm.id, :shutdown)
  end

  it "test_should_destroy_vm" do
    name = 'd-'+Time.now.to_i.to_s
    vm = @client.create_vm(:name => name, :template =>@blank_template_id, :cluster => @cluster)
    @client.destroy_vm(vm.id)
  end

  it "test_should_update_vm" do
    name = 'vmu-'+Time.now.to_i.to_s
    @client.update_vm(:id => @vm.id, :name=> name, :cluster => @cluster)
  end

  it "test_should_create_a_vm" do
    name = 'c-'+Time.now.to_i.to_s
    vm = @client.create_vm(:name => name, :template => @blank_template_id, :cluster => @cluster)
    vm.class.to_s.should eql("OVIRT::VM")
    @client.destroy_vm(vm.id)
  end

  it "test_should_update_volume" do
    @client.update_volume(@vm.id, @vm.volumes.first.id, :size => 10737418240)
    while @client.vm(@vm.id).volumes.first.status != 'ok' do
    end
    @client.vm(@vm.id).volumes.first.size.should eql("10737418240")
  end
end

shared_examples_for "VM Life cycle without template" do

  before(:all) do
    name = 'vm-'+Time.now.to_i.to_s
    @cluster = @client.clusters.select{|c| c.name == cluster_name}.first.id
    @vm = @client.create_vm(:name => name, :cluster => @cluster)
    @client.add_volume(@vm.id)
    @client.add_interface(@vm.id, :network_name => network_name)
    while !@client.vm(@vm.id).ready? do
    end
  end

  after(:all) do
    @client.destroy_vm(@vm.id)
  end

  it "test_should_return_a_vm" do
    @client.vm(@vm.id).id.should eql(@vm.id)
  end

  it "test_should_update_vm" do
    name = 'vmu-'+Time.now.to_i.to_s
    @client.update_vm(:id => @vm.id, :name=> name, :cluster => @cluster)
  end

  it "test_should_start_and_stop_vm" do
    @client.vm_action(@vm.id, :start)
    while !@client.vm(@vm.id).running? do
    end
    @client.vm_action(@vm.id, :shutdown)
  end
end

describe "Basic VM creation with instance type" do
  before(:all) do
    setup_client
    @name = 'vm-'+Time.now.to_i.to_s
    @cluster = @client.clusters.select{|c| c.name == cluster_name}.first.id
    if @config['instance_type']
      @instance_type = @client.instance_type(@config['instance_type'])
    else
      @instance_type = @client.instance_types.first
    end
  end

  it "test_should_create_vm_with_instance_type" do
    if @instance_type
      @vm = @client.create_vm(:name => @name, :instance_type => @instance_type.id, :cluster => @cluster)
      @vm.should_not be_nil
      while !@client.vm(@vm.id).ready? do
      end
      @client.destroy_vm(@vm.id) if @vm
    else
      skip "No instance type found, skip VM creation based on instance type"
    end
  end
end

describe "Admin API VM Life cycle" do

  before(:all) do
    setup_client
  end

  context 'admin basic vm and templates operations' do
    it_behaves_like "Basic VM Life cycle"
  end
end

describe "Admin API VM Life cycle without any template" do

  before(:all) do
    setup_client
  end

  context 'admin basic vm and templates operations' do
    it_behaves_like "VM Life cycle without template"
  end
end

describe "User API VM Life cycle" do

  before(:all) do
    setup_client :filtered_api => support_user_level_api
  end

  context 'user basic vm and templates operations' do
    it_behaves_like "Basic VM Life cycle"
  end
end

describe "VM API support functions" do

  before(:all) do
    setup_client
    if @client.templates.empty?
      name = 'vm-'+Time.now.to_i.to_s
      @cluster = @client.clusters.select{|c| c.name == cluster_name}.first.id
      vm = @client.create_vm(:name => name, :cluster => @cluster)
      @client.add_volume(vm.id)
      @client.add_interface(vm.id, :network_name => network_name)
      while !@client.vm(vm.id).ready? do
      end
      @client.create_template(:vm => vm.id, :name => "template-#{name}", :description => "test_template", :comment => "test_template")
    end

    @template_name = @config['template'] || @client.templates.first.name
    @template = @client.templates.find { |t| t.name == @template_name }.id
    @template_disks = @client.template_volumes(@template)
    @storagedomain = @client.storagedomains.first.id
    @storagedomain_name = @client.storagedomains.first.name
  end

  context 'options processing' do
    it "should process template option into disk decriptions" do
      t_id = @template
      opts = {:template => t_id}
      t_name = opts[:template_name]
      @client.process_vm_opts(opts)
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
    end

    it "should process template_name option into disk decriptions" do
      t_name = @template_name
      opts = {:template_name => t_name}
      t_id = opts[:template]
      @client.process_vm_opts(opts)
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
    end

    it "should process template and storagedomain options into disk decriptions" do
      t_id = @template
      s_id = @storagedomain
      opts = {:template => t_id,
              :storagedomain => s_id}
      t_name = opts[:template_name]
      s_name = opts[:storagedomain_name]
      @client.process_vm_opts(opts)
      opts[:disks].length.should eql(@template_disks.length)
      unless @template_disks.empty?
        opts[:disks].first[:id].should_not be_nil
        opts[:disks].first[:storagedomain].should eql(s_id)
      end
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
      opts[:storagedomain].should eql(s_id)
      opts[:storagedomain_name].should eql(s_name)
    end

    it "should process template_name and storagedomain options into disk decriptions" do
      t_name = @template_name
      s_id = @storagedomain
      opts = {:template_name => t_name,
              :storagedomain => s_id}
      t_id = opts[:template]
      s_name = opts[:storagedomain_name]
      @client.process_vm_opts(opts)
      opts[:disks].length.should eql(@template_disks.length)
      unless @template_disks.empty?
        opts[:disks].first[:id].should_not be_nil
        opts[:disks].first[:storagedomain].should eql(s_id)
      end
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
      opts[:storagedomain].should eql(s_id)
      opts[:storagedomain_name].should eql(s_name)
    end

    it "should process template and storagedomain_name options into disk decriptions" do
      t_id = @template
      s_name = @storagedomain_name
      opts = {:template => t_id,
              :storagedomain_name => s_name}
      t_name = opts[:template_name]
      s_id = opts[:storagedomain_id]
      @client.process_vm_opts(opts)
      opts[:disks].length.should eql(@template_disks.length)
      unless @template_disks.empty?
        opts[:disks].first[:id].should_not be_nil
        opts[:disks].first[:storagedomain].should eql(@storagedomain)
      end
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
      opts[:storagedomain].should eql(s_id)
      opts[:storagedomain_name].should eql(s_name)
    end

    it "should process template_name and storagedomain_name options into disk decriptions" do
      t_name = @template_name
      s_name = @storagedomain_name
      opts = {:template_name => t_name,
              :storagedomain_name => s_name}
      t_id = opts[:template]
      s_id = opts[:storagedomain]
      @client.process_vm_opts(opts)
      opts[:disks].length.should eql(@template_disks.length)
      unless @template_disks.empty?
        opts[:disks].first[:id].should_not be_nil
        opts[:disks].first[:storagedomain].should eql(@storagedomain)
      end
      opts[:template].should eql(t_id)
      opts[:template_name].should eql(t_name)
      opts[:storagedomain].should eql(s_id)
      opts[:storagedomain_name].should eql(s_name)
    end

  end
end

