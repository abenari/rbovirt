module OVIRT
  class DiskProfile < BaseObject
    attr_reader :disk_profile
    
    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      x = parse_xml_attributes!(xml)
      puts x
      self
    end
    
    private
    
    def parse_xml_attributes!(xml)
      @disk_profile = ((xml/'disk_profiles/disk_profile').first[:id] rescue nil)
      @name = ((xml/'disk_profiles/disk_profile').first.text rescue nil)
      @storage_domain = ((xml/'storagedomains').first[:id] rescue nil)
    end
  end
end