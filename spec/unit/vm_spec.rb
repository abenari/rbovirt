require "#{File.dirname(__FILE__)}/../spec_helper"


describe OVIRT::VM do

  context 'xml parsing' do
    before(:all) do
      @xml = <<END_HEREDOC
<vm id="76d29095-bc27-4cd0-8178-07e942aea549" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549">
<name>c-1326980484</name>
<actions>
<link rel="shutdown" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/shutdown"/>
<link rel="start" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/start"/>
<link rel="stop" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/stop"/>
<link rel="suspend" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/suspend"/>
<link rel="detach" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/detach"/>
<link rel="export" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/export"/>
<link rel="move" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/move"/>
<link rel="ticket" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/ticket"/>
<link rel="migrate" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/migrate"/>
<link rel="cancelmigration" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cancelmigration"/>
</actions>
<link rel="disks" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/disks"/>
<link rel="nics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics"/>
<link rel="cdroms" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cdroms"/>
<link rel="snapshots" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/snapshots"/>
<link rel="tags" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/tags"/>
<link rel="permissions" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/permissions"/>
<link rel="statistics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/statistics"/>
<nics>
<nic href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012" id="12345678-1234-1234-1234-123456789012">
<actions>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/deactivate" id="deactivate"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/activate" id="activate"/>
</actions>
<name>nic1</name>
<vm href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549" id="76d29095-bc27-4cd0-8178-07e942aea549"/>
<network href="/api/networks/00000000-0000-0000-0000-000000000000" id="00000000-0000-0000-0000-000000000000"/>
<linked>true</linked>
<interface>virtio</interface>
<mac address="00:11:22:33:44:55"/>
<active>true</active>
<plugged>true</plugged>
</nic>
</nics>
<disks>
<disk href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012" id="12345678-1234-1234-1234-123456789012">
<actions>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/deactivate" id="deactivate"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/move" id="move"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/activate" id="activate"/>
</actions>
<name>diskName</name>
<image_id>00000000-0000-0000-0000-000000000000</image_id>
<storage_domains>
<storage_domain id="11111111-1111-1111-1111-111111111111"/>
</storage_domains>
<size>53687091200</size>
<provisioned_size>53687091200</provisioned_size>
<actual_size>143360</actual_size>
<status><state>ok</state></status>
<interface>virtio</interface>
<format>cow</format>
<sparse>true</sparse>
<bootable>true</bootable>
<shareable>false</shareable>
<wipe_after_delete>false</wipe_after_delete>
<propagate_errors>false</propagate_errors>
<active>true</active>
</disk>
</disks>
<type>server</type>
<status>
<state>up</state>
</status>
<memory>536870912</memory>
<cpu>
<topology cores="1" sockets="1"/>
</cpu>
<os type="unassigned">
<boot dev="network"/>
<boot dev="hd"/>
</os>
<high_availability>
<enabled>false</enabled>
<priority>0</priority>
</high_availability>
<display>
<type>vnc</type>
<monitors>1</monitors>
</display>
<cluster id="b68980dc-3ab8-11e1-bcbf-5254005f0f6f" href="/api/clusters/b68980dc-3ab8-11e1-bcbf-5254005f0f6f"/>
<template id="00000000-0000-0000-0000-000000000000" href="/api/templates/00000000-0000-0000-0000-000000000000"/>
<start_time>2012-01-19T14:41:58.428Z</start_time>
<creation_time>2012-01-19T13:41:24.405Z</creation_time>
<origin>rhev</origin>
<stateless>false</stateless>
<placement_policy>
<affinity>migratable</affinity>
</placement_policy>
<memory_policy>
<guaranteed>536870912</guaranteed>
</memory_policy>
<usb>
<enabled>true</enabled>
</usb>
</vm>
END_HEREDOC

      @min_instance_type_xml = <<END_HEREDOC
<vm id="76d29095-bc27-4cd0-8178-07e942aea549" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549">
<name>c-1326980484</name>
<actions>
<link rel="shutdown" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/shutdown"/>
<link rel="start" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/start"/>
<link rel="stop" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/stop"/>
<link rel="suspend" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/suspend"/>
<link rel="detach" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/detach"/>
<link rel="export" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/export"/>
<link rel="move" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/move"/>
<link rel="ticket" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/ticket"/>
<link rel="migrate" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/migrate"/>
<link rel="cancelmigration" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cancelmigration"/>
</actions>
<link rel="disks" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/disks"/>
<link rel="nics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics"/>
<link rel="cdroms" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cdroms"/>
<link rel="snapshots" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/snapshots"/>
<link rel="tags" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/tags"/>
<link rel="permissions" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/permissions"/>
<link rel="statistics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/statistics"/>
<type>server</type>
<status>
<state>up</state>
</status>
<memory>536870912</memory>
<cpu>
<topology cores="1" sockets="1"/>
</cpu>
<os type="unassigned">
<boot dev="network"/>
<boot dev="hd"/>
</os>
<high_availability>
<enabled>false</enabled>
<priority>0</priority>
</high_availability>
<display>
<type>vnc</type>
<monitors>1</monitors>
</display>
<cluster id="b68980dc-3ab8-11e1-bcbf-5254005f0f6f" href="/api/clusters/b68980dc-3ab8-11e1-bcbf-5254005f0f6f"/>
<template id="00000000-0000-0000-0000-000000000000" href="/api/templates/00000000-0000-0000-0000-000000000000"/>
<instance_type id="00000000-0000-0000-0000-000000000001" href="/api/instancetypes/00000000-0000-0000-0000-000000000001"/>
<start_time>2012-01-19T14:41:58.428Z</start_time>
<creation_time>2012-01-19T13:41:24.405Z</creation_time>
<origin>rhev</origin>
<stateless>false</stateless>
<placement_policy>
<affinity>migratable</affinity>
</placement_policy>
<memory_policy>
<guaranteed>536870912</guaranteed>
</memory_policy>
<usb>
<enabled>true</enabled>
</usb>
</vm>
END_HEREDOC


      @min_xml = <<END_HEREDOC
<vm id="76d29095-bc27-4cd0-8178-07e942aea549" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549">
<name>c-1326980484</name>
<actions>
<link rel="shutdown" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/shutdown"/>
<link rel="start" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/start"/>
<link rel="stop" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/stop"/>
<link rel="suspend" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/suspend"/>
<link rel="detach" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/detach"/>
<link rel="export" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/export"/>
<link rel="move" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/move"/>
<link rel="ticket" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/ticket"/>
<link rel="migrate" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/migrate"/>
<link rel="cancelmigration" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cancelmigration"/>
</actions>
<link rel="disks" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/disks"/>
<link rel="nics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics"/>
<link rel="cdroms" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/cdroms"/>
<link rel="snapshots" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/snapshots"/>
<link rel="tags" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/tags"/>
<link rel="permissions" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/permissions"/>
<link rel="statistics" href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/statistics"/>
<type>server</type>
<status>
<state>up</state>
</status>
<memory>536870912</memory>
<cpu>
<topology cores="1" sockets="1"/>
</cpu>
<os type="unassigned">
<boot dev="network"/>
<boot dev="hd"/>
</os>
<high_availability>
<enabled>false</enabled>
<priority>0</priority>
</high_availability>
<display>
<type>vnc</type>
<monitors>1</monitors>
</display>
<cluster id="b68980dc-3ab8-11e1-bcbf-5254005f0f6f" href="/api/clusters/b68980dc-3ab8-11e1-bcbf-5254005f0f6f"/>
<template id="00000000-0000-0000-0000-000000000000" href="/api/templates/00000000-0000-0000-0000-000000000000"/>
<start_time>2012-01-19T14:41:58.428Z</start_time>
<creation_time>2012-01-19T13:41:24.405Z</creation_time>
<origin>rhev</origin>
<stateless>false</stateless>
<placement_policy>
<affinity>migratable</affinity>
</placement_policy>
<memory_policy>
<guaranteed>536870912</guaranteed>
</memory_policy>
<usb>
<enabled>true</enabled>
</usb>
</vm>
END_HEREDOC

    end

    before(:each) do
      @mock_client = double("mock_client")
      @mock_client.stub(:vm_interfaces) do
        xml = <<END_HEREDOC
<nic href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012" id="12345678-1234-1234-1234-123456789012">
<actions>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/deactivate" id="deactivate"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/activate" id="activate"/>
</actions>
<name>nic2</name>
<vm href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549" id="76d29095-bc27-4cd0-8178-07e942aea549"/>
<network href="/api/networks/00000000-0000-0000-0000-000000000000" id="00000000-0000-0000-0000-000000000000"/>
<linked>true</linked>
<interface>virtio</interface>
<mac address="00:11:22:33:44:55"/>
<active>true</active>
<plugged>true</plugged>
</nic>
END_HEREDOC
        [OVIRT::Interface::new(nil, Nokogiri::XML(xml).xpath('/').first)]
      end
      @mock_client.stub(:vm_volumes) do
        xml = <<END_HEREDOC
<disk href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012" id="12345678-1234-1234-1234-123456789012">
<actions>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/deactivate" id="deactivate"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/move" id="move"/>
<link href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012/activate" id="activate"/>
</actions>
<name>diskName2</name>
<image_id>00000000-0000-0000-0000-000000000000</image_id>
<storage_domains>
<storage_domain id="11111111-1111-1111-1111-111111111111"/>
</storage_domains>
<size>53687091200</size>
<provisioned_size>53687091200</provisioned_size>
<actual_size>143360</actual_size>
<status><state>ok</state></status>
<interface>virtio</interface>
<format>cow</format>
<sparse>true</sparse>
<bootable>true</bootable>
<shareable>false</shareable>
<wipe_after_delete>false</wipe_after_delete>
<propagate_errors>false</propagate_errors>
<active>true</active>
</disk>
END_HEREDOC
        [OVIRT::Volume::new(nil, Nokogiri::XML(xml).xpath('/').first)]
      end
    end

    it "should parse VM xml" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/').first)
      vm.class.should eql(OVIRT::VM)
    end

    it "create vm xml" do
      opts = {:cluster_name=>'cluster', :template_name =>'template'}
      xml = OVIRT::VM.to_xml(opts)
      xml.nil?.should eql(false)
    end

    it "create vm xml without description" do
      opts = {
          :cluster_name =>'cluster',
          :template_name =>'template',
      }
      xml = OVIRT::VM.to_xml(opts)
      xml.nil?.should eql(false)
      Nokogiri::XML(xml).xpath("//description").length.should eql(1)
      Nokogiri::XML(xml).xpath("//description")[0].children.length.should eql(0)
    end

    it "create vm xml with description" do
      opts = {
          :cluster_name =>'cluster',
          :template_name =>'template',
          :description => 'a description',
      }
      xml = OVIRT::VM.to_xml(opts)
      xml.nil?.should eql(false)
      Nokogiri::XML(xml).xpath("//description").length.should eql(1)
      Nokogiri::XML(xml).xpath("//description")[0].children.length.should eql(1)
      Nokogiri::XML(xml).xpath("//description")[0].children[0].text?.should eql(true)
      Nokogiri::XML(xml).xpath("//description")[0].content.should eql("a description")
    end

    it "create vm xml with disks" do
      disk = "00000000-0000-0000-0000-000000000000"
      storagedomain = "00000000-0000-0000-0000-000000000001"
      disks = [{:id => disk, :storagedomain => storagedomain}]
      opts = {
          :cluster_name => 'cluster',
          :disks => disks,
      }
      xml = OVIRT::VM.to_xml(opts)
      puts xml
      xml.nil?.should eql(false)
      Nokogiri::XML(xml).xpath("//disks").length.should eql(1)
      Nokogiri::XML(xml).xpath("//disks")[0].element_children.length.should eql(1)
      Nokogiri::XML(xml).xpath("//disks/disk[contains(@id,'#{disk}')]").length.should eql(1)
      Nokogiri::XML(xml).xpath("//disks/disk/storage_domains").length.should eql(1)
      Nokogiri::XML(xml).xpath("//disks/disk/storage_domains")[0].element_children.length.should eql(1)
      Nokogiri::XML(xml).xpath("//disks/disk/storage_domains/storage_domain[contains(@id,'#{storagedomain}')]").length.should eql(1)
    end

    it "create vm xml without instance_type" do
      opts = {:cluster_name=>'cluster'}
      xml = OVIRT::VM.to_xml(opts)
      xml.nil?.should eql(false)
      Nokogiri::XML(xml).xpath("//instance_type").length.should eql(0)
    end

    it "create vm xml with instance_type" do
      instance_type = "00000000-0000-0000-0000-000000000001"
      opts = {:cluster_name => 'cluster', :instance_type => instance_type}
      xml = OVIRT::VM.to_xml(opts)
      puts xml
      xml.nil?.should eql(false)
      Nokogiri::XML(xml).xpath("//instance_type").length.should eql(1)
      Nokogiri::XML(xml).xpath("//instance_type[contains(@id,'#{instance_type}')]").length.should eql(1)
    end


    it "should be running" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/').first)
      vm.running?.should eql(true)
    end

    it "should have one interface" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/').first)
      vm.interfaces.length.should eql(1)

      interface = vm.interfaces[0]
      interface.name.should eql('nic1')
      interface.mac.should eql('00:11:22:33:44:55')
      interface.interface.should eql('virtio')
      interface.plugged.should eql('true')
      interface.linked.should eql('true')
    end

    it "should have one volume" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/').first)
      vm.volumes.length.should eql(1)

      disk = vm.volumes[0]
      disk.storage_domain.should eql('11111111-1111-1111-1111-111111111111')
      disk.size.should eql('53687091200')
      disk.interface.should eql('virtio')
    end

    it "should have instance_type" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@min_instance_type_xml).xpath('/').first)
      vm.instance_type.id.should eql('00000000-0000-0000-0000-000000000001')
    end

    it "should still fallback to the client" do
      vm = OVIRT::VM.new(@mock_client, Nokogiri::XML(@min_xml).xpath('/').first)
      vm.volumes.length.should eql(1)
      vm.volumes[0].name.should eql('diskName2')

      vm.interfaces.length.should eql(1)
      vm.interfaces[0].name.should eql('nic2')
    end
  end

end
