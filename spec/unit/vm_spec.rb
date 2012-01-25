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

    it "should parse VM xml" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/'))
      vm.class.should eql(OVIRT::VM)
    end

    it "create vm xml" do
      opts = {:cluster_name=>'cluster', :template_name =>'template'}
      xml = OVIRT::VM.to_xml(opts)
      xml.nil?.should eql(false)
    end

    it "should be running" do
      vm = OVIRT::VM.new(nil, Nokogiri::XML(@xml).xpath('/'))
      vm.running?.should eql(true)
    end


  end

end
