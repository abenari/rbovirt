module OVIRT
  class Client
    def templates(opts={})
      path = "/templates"
      path += search_url(opts) unless filtered_api
      http_get(path).xpath('/templates/template').collect do |t|
        OVIRT::Template::new(self, t)
      end.compact
    end

    def template(template_id, opts={})
      results = http_get("/templates/%s" % template_id)
      template = OVIRT::Template::new(self, results.root)
      template
    end

    def create_template(opts)
      template = http_post("/templates", Template.to_xml(opts))
      OVIRT::Template::new(self, template.root)
    end

    def destroy_template(id)
      http_delete("/templates/%s" % id)
    end

    def template_interfaces template_id
      http_get("/templates/%s/nics" % template_id, http_headers).xpath('/nics/nic').collect do |nic|
        OVIRT::Interface::new(self, nic)
      end
    end

    def template_volumes template_id
      http_get("/templates/%s/disks" % template_id, http_headers).xpath('/disks/disk').collect do |disk|
        OVIRT::Volume::new(self, disk)
      end
    end
  end
end
