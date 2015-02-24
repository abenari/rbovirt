module OVIRT
  class DiskProfile < BaseObject
    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private
    def parse_xml_attributes!(xml)
      @disk_profile = ((xml/'disk_profile').first[:id] rescue nil)
      @name = ((xml/'name').first.text rescue nil)
      @storage_domain = ((xml/'storagedomains').first[:id] rescue nil)
    end
  end
end