module OVIRT
  class Client
    def storagedomain(sd_id)
      sd = http_get("/storagedomains/%s" % sd_id)
      OVIRT::StorageDomain::new(self, sd.root)
    end

    def storagedomains(opts={})
      path = "/storagedomains"
      path += search_url(opts) unless filtered_api
      http_get(path).xpath('/storage_domains/storage_domain').collect do |sd|
        storage_domain = OVIRT::StorageDomain::new(self, sd)
        #filter by role is not supported by the search language. The work around is to list all, then filter.
        (opts[:role].nil? || storage_domain.role == opts[:role]) ? storage_domain : nil
      end.compact
    end
  end
end
