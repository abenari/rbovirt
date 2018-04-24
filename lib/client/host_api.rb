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

    def approve_host(host_id, opts={})
        http_post("/hosts/%s/approve" % host_id, "<action></action>")
    end

    def reinstall_host(host_id, override_iptables=false, opts={})
        http_post("/hosts/%s/install" % host_id,
                  "<action>
                    <ssh>
                     <authentication_method>PublicKey</authentication_method>
                    </ssh>
                    <host>
                     <override_iptables>" + override_iptables.to_s + "</override_iptables>
                    </host>
                   </action>"
                 )
    end
  end
end
