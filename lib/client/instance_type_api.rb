module OVIRT
  class Client
    def instance_type(instance_type_id)
        begin
          instance_type = http_get("/instancetypes/%s" % instance_type_id)
          OVIRT::InstanceType::new(self, instance_type.root)
        rescue
          handle_fault $!
        end
      end

      def instance_types(opts={})
        search = opts[:search] ||""
        instance_types = http_get("/instancetypes?search=%s" % CGI.escape(search))
        instance_types.xpath('/instance_types/instance_type').collect do |it|
          OVIRT::InstanceType::new(self, it)
        end
      end
  end
end
