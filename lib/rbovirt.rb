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
require "restclient_ext/request"

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

    attr_reader :credentials, :api_entrypoint, :datacenter_id, :cluster_id, :filtered_api, :ca_cert_file, :ca_cert_store

    # Construct a new ovirt client class.
    # mandatory parameters
    #   username, password, api_entrypoint  - for example 'me@internal', 'secret', 'https://example.com/api'
    # optional parameters
    #   datacenter_id, cluster_id and filtered_api can be sent in this order for backward
    #   compatibility, or as a hash in the 4th parameter.
    #   datacenter_id - setting the datacenter at initialization will add a default scope to any subsequent call
    #                   to the client to the specified datacenter.
    #   cluster_id    - setting the cluster at initialization will add a default scope to any subsequent call
    #                   to the client to the specified cluster.
    #   filtered_api  - when set to false (default) will use ovirt administrator api, else it will use the user
    #                   api mode.
    #
    def initialize(username, password, api_entrypoint, options={}, backward_compatibility_cluster=nil, backward_compatibility_filtered=nil )
      if !options.is_a?(Hash)
        # backward compatibility optional parameters
        options = {:datacenter_id => options,
                   :cluster_id => backward_compatibility_cluster,
                   :filtered_api => backward_compatibility_filtered}
      end
      @api_entrypoint = api_entrypoint
      @credentials    = { :username => username, :password => password }
      @datacenter_id  = options[:datacenter_id]
      @cluster_id     = options[:cluster_id]
      @filtered_api   = options[:filtered_api]
      @ca_cert_file   = options[:ca_cert_file]
      @ca_cert_store  = options[:ca_cert_store]
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
        Nokogiri::XML(rest_client(suburl).get(http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_post(suburl, body, headers={})
      begin
        Nokogiri::XML(rest_client(suburl).post(body, http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_put(suburl, body, headers={})
      begin
        Nokogiri::XML(rest_client(suburl).put(body, http_headers(headers)))
      rescue
        handle_fault $!
      end
    end

    def http_delete(suburl)
      begin
        headers = {:accept => 'application/xml'}.merge(auth_header).merge(filter_header)
        Nokogiri::XML(rest_client(suburl).delete(headers))
      rescue
        handle_fault $!
      end
    end

    def auth_header
      # This is the method for strict_encode64:
      encoded_credentials = ["#{@credentials[:username]}:#{@credentials[:password]}"].pack("m0").gsub(/\n/,'')
      { :authorization => "Basic " + encoded_credentials }
    end

    def rest_client(suburl)
      if (URI.parse(@api_entrypoint)).scheme == 'https'
        verify_options = {:verify_ssl  => OpenSSL::SSL::VERIFY_PEER}
        verify_options[:ssl_cert_store] = ca_cert_store if ca_cert_store
        verify_options[:ssl_ca_file]    = ca_cert_file if ca_cert_file
      end
      RestClient::Resource.new(@api_entrypoint, verify_options)[suburl]
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
