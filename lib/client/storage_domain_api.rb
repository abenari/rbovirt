module OVIRT
  class Client
    def storagedomain(sd_id)
      sd = http_get("/storagedomains/%s" % sd_id)
      OVIRT::StorageDomain::new(self, sd.root)
    end

    def storagedomains(opts={})
      search= opts[:search] ||''
      http_get("/storagedomains?search=%s" % CGI.escape(search)).xpath('/storage_domains/storage_domain').collect do |sd|
        OVIRT::StorageDomain::new(self, sd)
      end
    end
  end
end