module OVIRT
  class Client
    def affinity_group(affinity_group_id, opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      ag_xml = http_get("/clusters/%s/affinitygroups/%s" % [cluster_id, affinity_group_id], http_headers)
      OVIRT::AffinityGroup.new(self, ag_xml.root)
    end

    def affinity_groups(opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_get("/clusters/%s/affinitygroups" % cluster_id, http_headers).xpath('/affinity_groups/affinity_group').collect do |ag|
        OVIRT::AffinityGroup.new(self, ag)
      end
    end

    def affinity_group_vms(affinity_group_id, opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_get("/clusters/%s/affinitygroups/%s/vms" % [cluster_id, affinity_group_id], http_headers).xpath('/vms/vm').collect do |vm_ref|
        OVIRT::VM.new(self, http_get("/vms/%s" % vm_ref.attribute('id').value, http_headers).root)
      end
    end

    def create_affinity_group(opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      OVIRT::AffinityGroup.new(self, http_post("/clusters/%s/affinitygroups" % cluster_id, OVIRT::AffinityGroup.to_xml(opts)).root)
    end

    def destroy_affinity_group(affinity_group_id, opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_delete("/clusters/%s/affinitygroups/%s" % [cluster_id, affinity_group_id])
    end

    def add_vm_to_affinity_group(affinity_group_id, vm_id, opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_post("/clusters/%s/affinitygroups/%s/vms" % [cluster_id, affinity_group_id], "<vm id='%s'/>" % vm_id)
    end
    
    def delete_vm_from_affinity_group(affinity_group_id, vm_id, opts={})
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_delete("/clusters/%s/affinitygroups/%s/vms/%s" % [cluster_id, affinity_group_id, vm_id])
    end
  end
end
