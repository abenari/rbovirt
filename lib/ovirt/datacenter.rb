
module OVIRT
  class DataCenter < BaseObject
    attr_reader :description, :status

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def clusters
      headers = {
        :accept => "application/xml; detail=datacenters"
      }
      headers.merge!(client.auth_header)
      clusters_list = OVIRT::client(client.api_entrypoint)["/clusters"].get(headers)
      cluster_arr = Client::parse_response(clusters_list).xpath('/clusters/cluster').map
      clusters_arr = []
      cluster_arr.each do |cluster|
        cluster = OVIRT::Cluster.new(self.client, cluster)
        clusters_arr << cluster if cluster.datacenter && cluster.datacenter.id == client.current_datacenter.id
      end
      clusters_arr
    end

    def cluster(cluster_id)
      headers = {
        :accept => "application/xml; detail=datacenters"
      }
      headers.merge!(client.auth_header)
      cluster_xml = OVIRT::client(client.api_entrypoint)["/clusters/%s" % cluster_id].get(headers)
      cluster = OVIRT::Cluster.new(self.client, cluster_xml)
      if cluster.datacenter && cluster.datacenter.id == client.datacenter_id
        cluster
      else
        nil
      end
    end

    def cluster_ids
      @cluster_ids ||= clusters.collect { |c| c.id }
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue nil)
      @status = (xml/'status').first.text
    end
  end
 
end