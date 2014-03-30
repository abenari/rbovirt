require 'yaml'
module OVIRT::RSpec::Endpoint

  def endpoint
    return  config['user'], config['password'], config['url'] , config['datacenter']
  end

  def network_name
    config['network'] || 'ovirtmgmt'
  end

  def support_user_level_api
    config['version'] && config['version'] > 3.1
  end

  def config
    @config ||= YAML.load(File.read(File.expand_path("../endpoint.yml", File.dirname(__FILE__))))
  end

end