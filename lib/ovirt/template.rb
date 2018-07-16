module OVIRT
  class Template < BaseObject
    attr_reader :description, :status, :cluster, :creation_time, :os, :storage, :display, :profile, :memory, :version
    attr_accessor :comment

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
          comment opts[:comment] || ''
          vm(:id => opts[:vm])
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def interfaces
      @interfaces ||= @client.template_interfaces(id)
    end

    def volumes
      @volumes ||= @client.template_volumes(id)
    end

    private
    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue '')
      @comment = ((xml/'comment').first.text rescue '')
      @version = TemplateVersion.new((xml/'version').first)
      @status = ((xml/'status').first.text rescue 'unknown')
      @memory = (xml/'memory').first.text
      @profile = (xml/'type').first.text
      if (xml/'cluster').first
        @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
      end
      @display = {
        :type => ((xml/'display/type').first.text rescue ''),
        :monitors => ((xml/'display/monitors').first.text rescue 0)
      }
      @cores = (xml/'cpu/topology').first[:cores].to_i
      @sockets = (xml/'cpu/topology').first[:sockets].to_i
      @storage = ((xml/'disks/disk/size').first.text rescue nil)
      @creation_time = (xml/'creation_time').text
      @os = {
          :type => (xml/'os').first[:type],
          :boot => (xml/'os/boot').collect {|boot| boot[:dev] }
      }
    end
  end
end
