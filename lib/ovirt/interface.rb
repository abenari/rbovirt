module OVIRT

  class Interface < BaseObject
    attr_reader :name, :mac, :interface, :network, :vm, :plugged, :linked

    def initialize(client=nil, xml={})
      if xml.is_a?(Hash)
        super(client, xml[:id], xml[:href], xml[:name])
        @network = xml[:network]
        @persisted = xml[:persisted]
        @interface = xml[:interface]
        @plugged = xml[:plugged]
        @linked = xml[:linked]
      else
        super(client, xml[:id], xml[:href], (xml/'name').first.text)
        parse_xml_attributes!(xml)
      end
      self
    end

    def self.to_xml(opts={})
      builder = Nokogiri::XML::Builder.new do
        nic{
          name_(opts[:name] || "nic-#{Time.now.to_i}")
          if opts[:network]
            network :id => opts[:network]
          else
            network{ name_(opts[:network_name] || 'ovirtmgmt') }
          end
          interface_(opts[:interface]) if opts[:interface]
          plugged_(opts[:plugged]) if opts[:plugged]
          linked_(opts[:linked]) if opts[:linked]
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def persisted?
      @persisted || !!id
    end

    def parse_xml_attributes!(xml)
     @mac = (xml/'mac').first[:address] rescue nil #template interfaces doesn't have MAC address.
     @interface = (xml/'interface').first.text
     @network = ((xml/'network').first[:id] rescue nil)
     @plugged = (xml/'plugged').first.text if (xml/'plugged').first
     @linked = (xml/'linked').first.text if (xml/'linked').first
     @vm = Link::new(@client, (xml/'vm').first[:id], (xml/'vm').first[:href]) if (xml/'vm') rescue nil
     @template = Link::new(@client, (xml/'template').first[:id], (xml/'template').first[:href]) rescue nil
    end

  end
end
