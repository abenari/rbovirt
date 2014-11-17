
module OVIRT
  class DataCenter < BaseObject
    attr_reader :description, :status, :local, :storage_type, :storage_format, :supported_versions, :version

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private

    def parse_xml_attributes!(xml)
      @description = (xml/'description').first.text rescue nil
      @status = (xml/'status').first.text.strip
      @local = parse_bool((xml/'local').first.text) rescue nil
      @storage_type = (xml/'storage_type').first.text rescue nil
      @storage_format = (xml/'storage_format').first.text rescue nil
      @supported_versions = (xml/'supported_versions').collect { |v|
        parse_version v
      }
      @version = parse_version xml rescue nil
    end
  end
 
end
