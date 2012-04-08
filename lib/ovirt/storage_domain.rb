module OVIRT
class StorageDomain < BaseObject
    attr_reader :available, :used, :kind, :address, :path, :role

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private

    def parse_xml_attributes!(xml)
      @available = ((xml/'available').first.text rescue nil)
      @used = ((xml/'used').first.text rescue nil)
      @role = (xml/'type').first.text
      @kind = (xml/'storage/type').first.text
      @address = ((xml/'storage/address').first.text rescue nil)
      @path = ((xml/'storage/path').first.text rescue nil)
    end
  end
end