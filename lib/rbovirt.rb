require "ovirt/base_object"
require "ovirt/cluster"
require "ovirt/datacenter"
require "ovirt/host"
require "ovirt/storage_domain"
require "ovirt/template"
require "ovirt/vm"
require "ovirt/volume"
require "ovirt/interface"
require "ovirt/network"
require "ovirt/quota"
require "ovirt/version"

require "client/vm_api"
require "client/template_api"
require "client/cluster_api"
require "client/host_api"
require "client/datacenter_api"
require "client/storage_domain_api"
require "client/quota_api"

require "nokogiri"
require "rest_client"

module OVIRT

  class OvirtVersionUnsupportedException < StandardError; end
  class OvirtException < StandardError
    def initialize(message)
      @message = message
      super
    end

    def message
      @message
    end
  end

  class Client

    attr_reader :credentials, :api_entrypoint, :datacenter_id, :cluster_id, :filtered_api

    def initialize(username, password, api_entrypoint, datacenter_id=nil, cluster_id=nil, filtered_api = false)
      @credentials = { :username => username, :password => password }
      @datacenter_id = datacenter_id
      @cluster_id = cluster_id
      @api_entrypoint = api_entrypoint
      @filtered_api = filtered_api
    end

    def api_version
      return @api_version unless @api_version.nil?
      xml = http_get("/")/'/api/product_info/version'
      @api_version = (xml/'version').first[:major] +"."+ (xml/'version').first[:minor]
    end

    def api_version?(major, minor=nil)
      (api_version.split('.')[0] == major) && (minor.nil? ? true : api_version.split('.')[1] == minor)
    end

    def floppy_hook?
      xml = http_get("/capabilities")
      !(xml/"version/custom_properties/custom_property[@name='floppyinject']").empty?
    end

    private
    def search_url opts
      search = opts[:search] || ("datacenter=%s" % current_datacenter.name)
      "?search=%s" % CGI.escape(search)
    end

    def current_datacenter
      @current_datacenter ||= self.datacenter_id ? datacenter(self.datacenter_id) : datacenters.first
    end

    def current_cluster
      @current_cluster ||= self.cluster_id ? cluster(self.cluster_id) : clusters.first
    end

    def http_get(suburl, headers={})
      begin
        Nokogiri::XML(RestClient::Resource.new(@api_entrypoint)[suburl].get(http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_post(suburl, body, headers={})
      begin
        Nokogiri::XML(RestClient::Resource.new(@api_entrypoint)[suburl].post(body, http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_put(suburl, body, headers={})
      begin
        Nokogiri::XML(RestClient::Resource.new(@api_entrypoint)[suburl].put(body, http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_delete(suburl)
      begin
        headers = {:accept => 'application/xml'}.merge(auth_header).merge(filter_header)
        Nokogiri::XML(RestClient::Resource.new(@api_entrypoint)[suburl].delete(headers))
      rescue
        handle_fault $!
      end
    end

    def auth_header
      # This is the method for strict_encode64:
      encoded_credentials = ["#{@credentials[:username]}:#{@credentials[:password]}"].pack("m0").gsub(/\n/,'')
      { :authorization => "Basic " + encoded_credentials }
    end

    def filter_header
      filtered_api ? { :filter => "true" } : {}
    end

    def base_url
      url = URI.parse(@api_entrypoint)
      "#{url.scheme}://#{url.host}:#{url.port}"
    end

    def self.parse_response(response)
      Nokogiri::XML(response)
    end

    def has_datacenter?(vm)
      (vm/'data_center').any?
    end

    def http_headers(headers ={})
      filter_header.merge(auth_header).merge({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      }).merge(headers)
    end

    def handle_fault(f)
      if f.is_a?(RestClient::BadRequest)
        fault = (Nokogiri::XML(f.http_body)/'//fault/detail')
        fault = fault.text.gsub(/\[|\]/, '') if fault
      end
      fault ||= f.message
      raise OvirtException::new(fault)
    end
  end

  class Link
    attr_accessor :id, :href, :client

    def initialize(client, id, href)
      @id, @href = id, href
      @client = client
    end

    def follow
      xml = Client::parse_response(OVIRT::client(@client.base_url)[@href].get(@client.auth_header))
      object_class = ::OVIRT.const_get(xml.root.name.camelize)
      object_class.new(@client, (xml.root))
    end
  end
end
