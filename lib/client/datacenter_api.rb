module OVIRT
  class Client
    def datacenter(datacenter_id)
        begin
          datacenter = http_get("/datacenters/%s" % datacenter_id)
          OVIRT::DataCenter::new(self, datacenter.root)
        rescue
          handle_fault $!
        end
      end

      def datacenters(opts={})
        search = opts[:search] ||""
        datacenters = http_get("/datacenters?search=%s" % CGI.escape(search))
        datacenters.xpath('/data_centers/data_center').collect do |dc|
          OVIRT::DataCenter::new(self, dc)
        end
      end
  end
end