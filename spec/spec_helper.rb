require 'openssl'
require 'rbovirt'
require 'rspec/core'
require 'rspec/mocks'
require 'socket'
require 'uri'
require 'yaml'

module OVIRT::RSpec

  # get ovirt ca certificate public key
  # * url - ovirt server url
  def ca_cert(url)
    parsed_url = URI.parse url
    begin
      tcp_socket = TCPSocket.open parsed_url.host, parsed_url.port
      ssl_socket = OpenSSL::SSL::SSLSocket.new tcp_socket
      ssl_socket.connect
      ssl_socket.peer_cert_chain.last.to_pem
    ensure
      unless ssl_socket.nil?
        ssl_socket.close
      end
      unless tcp_socket.nil?
        tcp_socket.close
      end
    end
  end

  def setup_client(options = {})
    user, password, url, datacenter = endpoint
    cert = ca_cert(url)
    store = OpenSSL::X509::Store.new().add_cert(OpenSSL::X509::Certificate.new(cert))
    opts = { :ca_cert_store => store }
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
