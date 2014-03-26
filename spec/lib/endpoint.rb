require 'yaml'
module OVIRT::RSpec::Endpoint

  def endpoint
    file = File.expand_path("../endpoint.yml", File.dirname(__FILE__))
    @endpoint ||= YAML.load(File.read(file))
    return  @endpoint['user'], @endpoint['password'], @endpoint['url'] , @endpoint['datacenter']
  end

  def support_user_level_api
    @endpoint['version'] && @endpoint['version'] > 3.1
  end

end