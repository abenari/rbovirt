module OVIRT

  class Nic < BaseObject
    attr_reader :name, :mac, :interface, :network, :vm

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def self.to_xml(opts={})
      builder = Nokogiri::XML::Builder.new do
        nic{
          name_(opts[:name] || 'eth0')
          network{
            name_(opts[:network] || 'ovirtmgmt')
          }
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def parse_xml_attributes!(xml)
     @name = (xml/'name').first.text
     @mac = (xml/'mac').first[:address]
     @interface = (xml/'interface').first.text
     @network = (xml/'network').first[:id]
     @vm = Link::new(@client, (xml/'vm').first[:id], (xml/'vm').first[:href])
    end

  end
end