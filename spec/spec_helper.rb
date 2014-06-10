require 'rspec/core'
require 'rspec/mocks'
require 'rbovirt'

module OVIRT::RSpec

  # get ovirt ca certificate public key
  # * url - ovirt server url
  def self.ca_cert(url)
    ca_url = URI.parse(url)
    ca_url.path = "/ca.crt"
    http = Net::HTTP.new(ca_url.host, ca_url.port)
    http.use_ssl = (ca_url.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(ca_url.path)
    http.request(request).body
  end

end

require "#{File.dirname(__FILE__)}/lib/endpoint"

RSpec.configure do |config|
  config.include OVIRT::RSpec::Endpoint
end
