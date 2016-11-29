module OVIRT
 class Network < BaseObject
    attr_reader :description, :datacenter, :cluster, :vlan_id, :mtu, :stp, :usages, :status

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue nil)
      @stp = ((xml/'stp').first.text rescue false)
      @mtu = ((xml/'mtu').first.text rescue nil)
      @vlan_id = ((xml/'vlan').first[:id] rescue nil)
      @usages = ((xml/'usages/usage').collect{ |usage| usage.text } rescue [])
      @datacenter = Link::new(@client, (xml/'data_center').first[:id], (xml/'data_center').first[:href]) unless (xml/'data_center').empty?
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href]) unless (xml/'cluster').empty?
      @status = ((xml/'status/state').first.text rescue nil)
    end

  end
end
