require "ovirt/base_object"
require "ovirt/cluster"
require "ovirt/datacenter"
require "ovirt/host"
require "ovirt/storage_domain"
require "ovirt/template"
require "ovirt/vm"
require "ovirt/volume"
require "ovirt/interface"

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

    attr_reader :credentials, :api_entrypoint, :datacenter_id, :cluster_id

    def initialize(username, password, api_entrypoint, datacenter_id=nil, cluster_id=nil)
      @credentials = { :username => username, :password => password }
      @datacenter_id = datacenter_id
      @cluster_id = cluster_id
      @api_entrypoint = api_entrypoint
    end

    def vm(vm_id, opts={})
      headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      vm = OVIRT::VM::new(self,  http_get("/vms/%s" % vm_id, headers).root)
      # optional eager loading
      vm.interfaces = interfaces(vm_id) if opts[:include] && opts[:include].include?(:interfaces)
      vm.volumes = volumes(vm_id) if opts[:include] && opts[:include].include?(:volumes)
      vm
    end

    def interfaces vm_id
      http_get("/vms/%s/nics" % vm_id, http_headers).xpath('/nics/nic').collect do |nic|
        OVIRT::Interface::new(self, nic)
      end
    end

    def volumes vm_id
      http_get("/vms/%s/disks" % vm_id, http_headers).xpath('/disks/disk').collect do |disk|
        OVIRT::Volume::new(self, disk)
      end
    end

    def vms(opts={})
      headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
      http_get("/vms?search=%s" % CGI.escape(search), headers).xpath('/vms/vm').collect do |vm|
        OVIRT::VM::new(self, vm)
      end
    end

    def vm_action(id, action, opts={})
      xml_response = http_post("/vms/%s/%s" % [id, action],'<action/>', opts)
      return (xml_response/'action/status').first.text.strip.upcase=="COMPLETE"
    end

    def destroy_vm(id)
      http_delete("/vms/%s" % id)
    end

    def api_version
      xml = http_get("/")/'/api/product_info/version'
      (xml/'version').first[:major] +"."+ (xml/'version').first[:minor]
    end

    def api_version?(major)
      api_version.split('.')[0] == major
    end

    def cluster_version?(cluster_id, major)
      c = cluster(cluster_id)
      c.version.split('.')[0] == major
    end

    def create_vm(template_name, opts)
      cluster_name = opts[:cluster_name] || clusters.first.name
      result_xml = http_post("/vms",OVIRT::VM.to_xml(template_name, cluster_name, opts))
      OVIRT::VM::new(self, result_xml.root)
    end

    def add_volume(vm_id, opts={})
      storage_domain_id = opts[:storage_domain] || storagedomains.first.id
      result_xml = http_post("/vms/%s/disks" % vm_id, OVIRT::Volume.to_xml(storage_domain_id, opts))
    end


    def add_interface(vm_id, opts={})
      http_post("/vms/%s/nics" % vm_id, OVIRT::Interface.to_xml( opts))
    end

    def create_template(vm_id, opts)
      template = http_post("/templates", Template.to_xml(vm_id, opts))
      OVIRT::Template::new(self, template.root)
    end

    def destroy_template(id)
      http_delete("/templates/%s" % id)
    end

    def templates(opts={})
      search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
      http_get("/templates?search=%s" % CGI.escape(search)).xpath('/templates/template').collect do |t|
        OVIRT::Template::new(self, t)
      end.compact
    end

    def template(template_id)
      template = http_get("/templates/%s" % template_id)
      OVIRT::Template::new(self, template.root)
    end

    def datacenters(opts={})
      search = opts[:search] ||""
      datacenters = http_get("/datacenters?search=%s" % CGI.escape(search))
      datacenters.xpath('/data_centers/data_center').collect do |dc|
        OVIRT::DataCenter::new(self, dc)
      end
    end

    def clusters(opts={})
      headers = {:accept => "application/xml; detail=datacenters"}
      search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
      http_get("/clusters?search=%s" % CGI.escape(search), headers).xpath('/clusters/cluster').collect do |cl|
        OVIRT::Cluster.new(self, cl)
      end
    end

    def cluster(cluster_id)
      headers = {:accept => "application/xml; detail=datacenters"}
      cluster_xml = http_get("/clusters/%s" % cluster_id, headers)
      OVIRT::Cluster.new(self, cluster_xml)
    end

    def current_datacenter
      @current_datacenter ||= self.datacenter_id ? datacenter(self.datacenter_id) : datacenters.first
    end

    def current_cluster
      @current_cluster ||= self.cluster_id ? cluster(self.cluster_id) : clusters.first
    end

    def datacenter(datacenter_id)
      begin
        datacenter = http_get("/datacenters/%s" % datacenter_id)
        OVIRT::DataCenter::new(self, datacenter.root)
      rescue
        handle_fault $!
      end
    end

    def host(host_id, opts={})
      xml_response = http_get("/hosts/%s" % host_id)
      OVIRT::Host::new(self, xml_response.root)
    end
    
    def hosts(opts={})
      search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
      http_get("/hosts?search=%s" % CGI.escape(search)).xpath('/hosts/host').collect do |h|
        OVIRT::Host::new(self, h)
      end
    end

    def storagedomain(sd_id)
      sd = http_get("/storagedomains/%s" % sd_id)
      OVIRT::StorageDomain::new(self, sd.root)
    end
    
    def storagedomains(opts={})
      search= opts[:search] ||''
      http_get("/storagedomains?search=%s" % CGI.escape(search)).xpath('/storage_domains/storage_domain').collect do |sd|
        OVIRT::StorageDomain::new(self, sd)
      end
    end

    private

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

    def http_delete(suburl)
      begin
        headers = {:accept => 'application/xml'}.merge(auth_header)
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

    def base_url
      url = URI.parse(@api_entrypoint)
      "#{url.scheme}://#{url.host}:#{url.port}"
    end

    def self.parse_response(response)
      Nokogiri::XML(response)
    end

    def has_datacenter?(vm)
      value=!(vm/'data_center').empty?
      value
    end

    def http_headers(headers ={})
      headers.merge({
        :content_type => 'application/xml',
        :accept => 'application/xml'
      }).merge(auth_header)
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