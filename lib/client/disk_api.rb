module OVIRT
  class Client
    def disks(opts={})
      path = "/disks" + search_url(opts)
      http_get(path).xpath('/disks/disk').collect do |d|
        OVIRT::Volume.new(self, d)
      end
    end

    def disk(disk_id)
      disk_xml = http_get("/disks/%s" % disk_id)
      OVIRT::Volume.new(self, disk_xml.root)
    end
  end
end
