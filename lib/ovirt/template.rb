module OVIRT
  class Template < BaseObject
    attr_reader :description, :status, :cluster

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def self.to_xml(opts={})
      builder = Nokogiri::XML::Builder.new do
        template_ {
          name_ opts[:name] || "t-#{Time.now.to_i}"
          description opts[:description] || ''
          vm(:id => opts[:vm])
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    private

    def parse_xml_attributes!(xml)

      @description = ((xml/'description').first.text rescue '')
      @status = ((xml/'status').first.text rescue 'unknown')
      @memory = (xml/'memory').first.text
      @profile = (xml/'type').first.text
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
      @display = {
        :type => (xml/'display/type').first.text,
        :monitors => (xml/'display/monitors').first.text
      }
      @cores = ((xml/'cpu/topology').first[:cores] rescue nil)
      @storage = ((xml/'disks/disk/size').first.text rescue nil)
      @creation_time = (xml/'creation_time').text
      @os = {
          :type => (xml/'os').first[:type],
          :boot => (xml/'os/boot').collect {|boot| boot[:dev] }
      }
    end
  end
end