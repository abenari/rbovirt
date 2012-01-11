module OVIRT
  class Template < BaseObject
    attr_reader :description, :status, :cluster

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def self.to_xml(vm_id, opts={})
      builder = Nokogiri::XML::Builder.new do
        template_ {
          name_ opts[:name] || "t-#{Time.now.to_i}"
          description opts[:description] || ''
          vm(:id => vm_id)
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue nil)
      @status = (xml/'status').first.text
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
    end
  end
end