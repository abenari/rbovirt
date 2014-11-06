module OVIRT

  class Volume < BaseObject
    attr_reader :size, :disk_type, :bootable, :interface, :format, :sparse, :status, :storage_domain, :vm, :quota, :disk_profile

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def self.to_xml(storage_domain_id,opts={})
       builder = Nokogiri::XML::Builder.new do
        disk_{
          storage_domains_{
            storage_domain_(:id => storage_domain_id)
          }
          size_(opts[:size] || 8589934592)
          type_(opts[:type] || 'data')
          bootable_(opts[:bootable] || 'true')
          disk_profile_(:id => opts[:disk_profile] || nil)
          interface_(opts[:interface] || 'virtio')
          format_(opts[:format] || 'cow')
          sparse_(opts[:sparse] || 'true')
          if opts[:quota]
            quota_( :id => opts[:quota])
          end
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def parse_xml_attributes!(xml)
     @storage_domain = ((xml/'storage_domains/storage_domain').first[:id] rescue nil)
     @size = (xml/'size').first.text
     @disk_type = ((xml/'type').first.text rescue nil)
     @bootable = (xml/'bootable').first.text
     @interface = (xml/'interface').first.text
     @format = ((xml/'format').first.text rescue nil)
     @format = ((xml/'format').first.text rescue nil)
     @sparse = ((xml/'sparse').first.text rescue nil)
     @status = ((xml/'status').first.text rescue nil)
     @disk_profile = Link::new(@client, (xml/'disk_profile').first[:id], (xml/'disk_profile').first[:href]) rescue nil
     @status ||= ((xml/'status/state').first.text rescue nil)
     @vm = Link::new(@client, (xml/'vm').first[:id], (xml/'vm').first[:href]) rescue nil
     @quota = ((xml/'quota').first[:id] rescue nil)
    end

  end
end
