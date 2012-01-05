module OVIRT
  class VM < BaseObject
    attr_reader :description, :status, :memory, :profile, :display, :host, :cluster, :template, :macs
    attr_reader :storage, :cores, :username, :creation_time
    attr_reader :ip, :vnc

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      @username = client.credentials[:username]
      parse_xml_attributes!(xml)
      self
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue '')
      @status = (xml/'status').first.text
      @memory = (xml/'memory').first.text
      @profile = (xml/'type').first.text
      @template = Link::new(@client, (xml/'template').first[:id], (xml/'template').first[:href])
      @host = Link::new(@client, (xml/'host').first[:id], (xml/'host').first[:href]) rescue nil
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
      @display = {
        :type => (xml/'display/type').first.text,
        :address => ((xml/'display/address').first.text rescue nil),
        :port => ((xml/'display/port').first.text rescue nil),
        :monitors => (xml/'display/monitors').first.text
      }
      @cores = ((xml/'cpu/topology').first[:cores] rescue nil)
      @storage = ((xml/'disks/disk/size').first.text rescue nil)
      @macs = (xml/'nics/nic/mac').collect { |mac| mac[:address] }
      @creation_time = (xml/'creation_time').text
      @ip = ((xml/'guest_info/ip').first[:address] rescue nil)
      @vnc = {
        :address => ((xml/'display/address').first.text rescue "127.0.0.1"),
        :port => ((xml/'display/port').first.text rescue "5890")
      } unless @ip
    end

  end
end