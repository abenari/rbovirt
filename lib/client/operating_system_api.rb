module OVIRT
  class Client
    def operating_systems
      operating_systems = http_get('/operatingsystems')
      operating_systems.xpath('/operating_systems/operating_system').collect do |os|
        OVIRT::OperatingSystem::new(self, os)
      end
    end
  end
end
