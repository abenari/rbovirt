module OVIRT
  class Client
    def diskprofile(dp_id)
      dp = http_get("/diskprofiles/%s" % dp_id)
      OVIRT::DiskProfile::new(self, dp.root)
    end

    def diskprofiles(opts={})
      path = "/diskprofiles"
      path += search_url(opts) unless filtered_api
      http_get(path).xpath('/disk_profiles/disk_profile').collect do |dp|
        OVIRT::DiskProfile::new(self,dp)
      end.compact
    end
  end
end