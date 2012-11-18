module OVIRT
  class Client
    def host(host_id, opts={})
      xml_response = http_get("/hosts/%s" % host_id)
      OVIRT::Host::new(self, xml_response.root)
    end

    def hosts(opts={})
      path = "/hosts"
      path += search_url(opts) unless filtered_api
      http_get(path).xpath('/hosts/host').collect do |h|
        OVIRT::Host::new(self, h)
      end
    end
  end
end
