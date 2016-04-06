module OVIRT
  class TemplateVersion
    attr_reader :base_template, :version_number, :version_name
    def initialize(xml)
      parse_xml_attributes(xml) if xml
    end

    def parse_xml_attributes(xml)
      @base_template = (xml/"base_template").first[:id]
      @version_number = (xml/"version_number").first.text
      @version_name = ((xml/"version_name").first.text rescue nil)
    end
  end
end
