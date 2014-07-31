require 'rspec/core'
require 'rspec/mocks'
require 'rbovirt'
require 'yaml'

module OVIRT::RSpec

  # get ovirt ca certificate public key
  # * url - ovirt server url
  def ca_cert(url)
    ca_url = URI.parse(url)
    ca_url.path = "/ca.crt"
    http = Net::HTTP.new(ca_url.host, ca_url.port)
    http.use_ssl = (ca_url.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(ca_url.path)
    http.request(request).body
  end

  def setup_client(options = {})
    user, password, url, datacenter = endpoint
    opts = {
      :ca_cert_file => "#{File.dirname(__FILE__)}/ca_cert.pem"
    }
    @client = ::OVIRT::Client.new(user, password, url, opts)
    datacenter_id = @client.datacenters.find{|x| x.name == datacenter}.id rescue raise("Cannot find datacenter #{datacenter}")
    opts.merge!(:datacenter_id => datacenter_id)
    opts.merge! options
    @client = ::OVIRT::Client.new(user, password, url, opts)
  end

  def endpoint
    return config['user'], config['password'], config['url'], config['datacenter']
  end

  def cluster_name
    config['cluster'] || 'Default'
  end

  def network_name
    config['network'] || 'ovirtmgmt'
  end

  def support_user_level_api
    config['version'] && config['version'] > 3.1
  end

  def config
    @config ||= YAML.load(File.read(File.expand_path("endpoint.yml", File.dirname(__FILE__))))
  end

end

RSpec.configure do |config|
  config.include OVIRT::RSpec
end
