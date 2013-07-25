module OVIRT
  class Client
    def quota(quota_id, opts={})
      q = http_get("/datacenters/%s/quotas/%s" % [current_datacenter.id, quota_id])
      OVIRT::Quota::new(self, q.root)
    end

    def quotas(opts={})
      http_get("/datacenters/%s/quotas" % CGI.escape(current_datacenter.id)).xpath('/quotas/quota').collect do |q|
        OVIRT::Quota::new(self, q)
      end.compact
    end
  end
end
