module OVIRT
  class Client
    def host(host_id, opts={})
      xml_response = http_get("/hosts/%s" % host_id)
      OVIRT::Host::new(self, xml_response.root)
    end

    def hosts(opts={})
      search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
      http_get("/hosts?search=%s" % CGI.escape(search)).xpath('/hosts/host').collect do |h|
        OVIRT::Host::new(self, h)
      end
    end
  end
end
