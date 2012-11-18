module OVIRT::RSpec::Endpoint

  def endpoint
    file = File.expand_path("../endpoint.yml", File.dirname(__FILE__))
    @endpoint ||= YAML.load(File.read(file))
    user = @endpoint['user']
    password= @endpoint['password']
    hostname = @endpoint['hostname']
    port = @endpoint['port']
    url = "http://#{hostname}:#{port}/api"
    return user, password, url
  end

  def support_user_level_api
    @endpoint['version'] && @endpoint['version'] > 3.1
  end

end