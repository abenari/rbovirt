module OVIRT

  class AffinityGroup < BaseObject
    attr_reader :name, :positive, :enforcing

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def self.to_xml(opts={})
       builder = Nokogiri::XML::Builder.new do
        affinity_group_{
          if opts[:name]
            name_(opts[:name])
          end
          if opts[:positive]
            positive_(opts[:positive])
          end
          if opts[:enforcing]
            enforcing_(opts[:enforcing])
          end
        }
       end
       Nokogiri::XML(builder.to_xml).root.to_s
    end

    def parse_xml_attributes!(xml)
     @name = (xml/'name').first.text
     @positive = (xml/'positive').first.text if (xml/'positive')
     @enforcing = (xml/'enforcing').first.text if (xml/'enforcing')
     @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href]) rescue nil
    end
  end
end
