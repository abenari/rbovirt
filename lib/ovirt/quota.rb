module OVIRT
class Quota < BaseObject
    attr_reader :name, :description

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private
    def parse_xml_attributes!(xml)
      @desciption = ((xml/'description').first.text rescue nil)
    end
  end
end

