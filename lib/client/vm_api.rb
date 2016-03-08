module OVIRT
  class Client
    def vm(vm_id, opts={})
      headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      OVIRT::VM::new(self,  http_get("/vms/%s" % vm_id, headers).root)
    end

    def vms(opts={})
      if opts[:without_details]
        headers = {:accept => "application/xml"}
      else
        headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      end
      path = "/vms"
      path += search_url(opts) unless filtered_api
      http_get(path, headers).xpath('/vms/vm').collect do |vm|
        OVIRT::VM::new(self, vm)
      end
    end

    def process_vm_opts(opts)
      if (opts[:template] or opts[:template_name]) and (opts[:storagedomain] or opts[:storagedomain_name])
        template_id = opts[:template] || templates.select{|t| t.name == opts[:template_name]}.first.id
        template_disks = template_volumes(template_id)
        storagedomain_id = opts[:storagedomain] || storagedomains.select{|s| s.name == opts[:storagedomain_name]}.first.id

        # Make sure the 'clone' option is set if any of the disks defined by
        # the template is stored on a different storage domain than requested
        opts[:clone] = true unless opts[:clone] == true || template_disks.empty? || template_disks.all? { |d| d.storage_domain == storagedomain_id }

        # Create disks map
        opts[:disks] = template_disks.collect { |d| {:id => d.id, :storagedomain => storagedomain_id} }
      end
    end

    def create_vm(opts)
      cluster_major_ver, cluster_minor_ver = cluster_version(self.cluster_id)

      if opts[:user_data] and not opts[:user_data].empty?
        if api_version?('3') and cluster_major_ver >= 3
          if cluster_minor_ver >= 3
            opts[:user_data_method] = :payload_v3_3
          elsif cluster_minor_ver >= 1
            opts[:user_data_method] = :payload
          elsif floppy_hook?
            opts[:user_data_method] = :custom_property
          else
            raise "Required VDSM hook 'floppyinject' not supported by RHEV-M"
          end
        else
          raise BackendVersionUnsupportedException.new
        end
      end

      process_vm_opts(opts)

      opts[:cluster_name] ||= clusters.first.name unless opts[:cluster]
      OVIRT::VM::new(self, http_post("/vms",OVIRT::VM.to_xml(opts)).root)
    end

    def vm_interfaces vm_id
      begin
        http_get("/vms/%s/nics" % vm_id, http_headers).xpath('/nics/nic').collect do |nic|
          OVIRT::Interface::new(self, nic)
        end
      rescue => e # Catch case were vm_id is destroyed.
        raise e unless e.message =~ /Entity not found/
        []
      end
    end 

    def destroy_interface(vm_id, interface_id)
      http_delete("/vms/%s/nics/%s" % [vm_id, interface_id])
    end

    def add_interface(vm_id, opts={})
      http_post("/vms/%s/nics" % vm_id, OVIRT::Interface.to_xml( opts))
    end

    def update_interface(vm_id, interface_id, opts={})
      http_put("/vms/%s/nics/%s" % [vm_id, interface_id], OVIRT::Interface.to_xml( opts))
    end

    def vm_volumes vm_id
      begin
        volumes = http_get("/vms/%s/disks" % vm_id, http_headers).xpath('/disks/disk').collect do |disk|
          OVIRT::Volume::new(self, disk)
        end
      rescue => e # Catch case were vm_id is destroyed.
        raise e unless e.message =~ /Entity not found/
        volumes = []
      end
      #this is a workaround to a bug that the list is not sorted by default.
      volumes.sort{ |l, r| l.name <=> r.name }
    end

    def add_volume(vm_id, opts={})
      search = opts[:search] || ("datacenter=%s" % current_datacenter.name)
      opts[:storage_domain_id] = opts[:storage_domain] || storagedomains(:role => 'data', :search => search).first.id
      # If no size is given, default to a volume size of 8GB
      opts[:size] = 8 * 1024 * 1024 * 1024 unless opts[:size]
      opts[:type] = 'data' unless opts[:type]
      opts[:bootable] = 'true' unless opts[:bootable]
      opts[:interface] = 'virtio' unless opts[:interface]
      opts[:format] = 'cow' unless opts[:format]
      opts[:sparse] = 'true' unless opts[:sparse]
      http_post("/vms/%s/disks" % vm_id, OVIRT::Volume.to_xml(opts))
    end

    def destroy_volume(vm_id, vol_id)
      http_delete("/vms/%s/disks/%s" % [vm_id, vol_id])
    end

    def update_volume(vm_id, vol_id, opts={})
      http_put("/vms/%s/disks/%s" % [vm_id, vol_id], OVIRT::Volume.to_xml(opts))
    end

    def volume_active?(vm_id, vol_id)
      http_response = http_get("/vms/%s/disks/%s" % [vm_id, vol_id, http_headers])
      http_response.xpath("/disk/active").first.text.upcase == "TRUE"
    end

    def activate_volume(vm_id, vol_id)
      http_post("/vms/%s/disks/%s/activate" % [vm_id, vol_id], '<action/>') unless volume_active?(vm_id, vol_id)
    end

    def deactivate_volume(vm_id, vol_id)
      http_post("/vms/%s/disks/%s/deactivate" % [vm_id, vol_id], '<action/>') if volume_active?(vm_id, vol_id)
    end

    def attach_volume(vm_id, vol_id, activate=true)
      http_post("/vms/%s/disks" % vm_id, "<disk id='%s'/>" % vol_id)
      activate_volume(vm_id, vol_id) if activate
    end

    def detach_volume(vm_id, vol_id)
      deactivate_volume(vm_id, vol_id)
      http_delete("/vms/%s/disks/%s" % [vm_id, vol_id], '<action><detach>true</detach></action>')
    end

    def vm_action(id, action, opts={})
      xml_response = http_post("/vms/%s/%s" % [id, action],'<action/>', opts)
      return (xml_response/'action/status').first.text.strip.upcase=="COMPLETE"
    end

    def vm_start_with_cloudinit(id, opts={})
      # Get the api and cluster version on which the VM is provisioned.
      # This is required for VM::cloudinit.
      opts.merge!(
        :cluster_version => cluster_version(vm(id).cluster.id),
        :api_version => api_version.split('.').map(&:to_i)
      )
      xml = OVIRT::VM.cloudinit(opts)
      xml_response = http_post("/vms/%s/%s" % [id, 'start'], xml, {} )
      return (xml_response/'action/status').first.text.strip.upcase=="COMPLETE"
    end

    def destroy_vm(id)
      http_delete("/vms/%s" % id)
    end

    def set_ticket(vm_id, options={})
      ticket = OVIRT::VM.ticket(options)
      xml_response = http_post("/vms/%s/ticket" % vm_id, ticket)
      (xml_response/'action/ticket/value').first.text
    end

    def update_vm(opts)
      opts[:cluster_name] ||= clusters.first.name
      result_xml = http_put("/vms/%s" % opts[:id], OVIRT::VM.to_xml(opts))
      OVIRT::VM::new(self, result_xml.root)
    end
  end
end
