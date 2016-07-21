require "#{File.dirname(__FILE__)}/../spec_helper"

describe OVIRT::Volume do

xml = <<END_HEREDOC
<disk href="/api/vms/76d29095-bc27-4cd0-8178-07e942aea549/nics/12345678-1234-1234-1234-123456789012" id="12345678-1234-1234-1234-123456789012">
<name>disk1</name>
<size>53687091200</size>
<provisioned_size>53687091200</provisioned_size>
<actual_size>143360</actual_size>
<shareable>false</shareable>
<propagate_errors>false</propagate_errors>
<active>true</active>
</disk>
END_HEREDOC
    vol =  OVIRT::Volume::new(nil, Nokogiri::XML(xml).xpath('/').first)

    it "volume's bootable should be nil, since it was not specified" do
      vol.bootable.should eql(nil)
    end

    it "volume's interface should be nil, since it was not specified" do
      vol.interface.should eql(nil)
    end

end
