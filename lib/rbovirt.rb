require "ovirt/base_object"
require "ovirt/cluster"
require "ovirt/datacenter"
require "ovirt/host"
require "ovirt/storage_domain"
require "ovirt/template"
require "ovirt/vm"

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

    attr_reader :credentials, :api_entrypoint, :datacenter_id

    def initialize(username, password, api_entrypoint, datacenter_id=nil)
      @credentials = { :username => username, :password => password }
      @datacenter_id = datacenter_id
      @api_entrypoint = api_entrypoint
    end

    def vm(vm_id)
      headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      vm = http_get("/vms/%s" % vm_id, headers).root
      OVIRT::VM::new(self, vm)
    end

    def vms(opts={})
      headers = {:accept => "application/xml; detail=disks; detail=nics; detail=hosts"}
      http_get("/vms",headers).xpath('/vms/vm').collect do |vm|
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
      result_xml = http_get("/")
      (result_xml/'/api/product_info/version')
    end

    def api_version?(major)
      api_version.first[:major].strip == major
    end

    def cluster_version?(cluster_id, major)
      result_xml = http_get("/clusters/%s" % cluster_id)
      (result_xml/'/cluster/version').first[:major].strip == major
    end

    def create_vm(template_name, opts)
      cluster_name = opts[:cluster_name] || clusters.first.name
      result_xml = http_post("/vms",OVIRT::VM.to_xml(template_name, cluster_name, opts))
      OVIRT::VM::new(self, result_xml.root)
    end

    def add_disk(vm_id, opts={})
      storage_domain_id = opts[:storage_domain] || storagedomains.first.id
      result_xml = http_post("/vms/%s/disks" % vm_id, VM.disk_xml(storage_domain_id, opts))
    end


    def add_nic(vm_id, opts={})
      http_post("/vms/%s/nics" % vm_id, VM.nic_xml( opts))
    end

    def create_template(vm_id, opts)
      template = http_post("/templates", Template.to_xml(vm_id, opts))
      OVIRT::Template::new(self, template.root)
    end

    def destroy_template(id)
      http_delete("/templates/%s" % id)
    end

    def templates(opts={})
      templates = http_get("/templates")
      templates.xpath('/templates/template').collect do |t|
        OVIRT::Template::new(self, t)
      end.compact
    end

    def template(template_id)
      template = http_get("/templates/%s" % template_id)
      OVIRT::Template::new(self, template.root)
    end

    def datacenters(opts={})
      datacenters = http_get("/datacenters")
      datacenters.xpath('/data_centers/data_center').collect do |dc|
        OVIRT::DataCenter::new(self, dc)
      end
    end

    def clusters
      headers = {:accept => "application/xml; detail=datacenters"}
      http_get("/clusters", headers).xpath('/clusters/cluster').collect do |cl|
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
      http_get("/hosts").xpath('/hosts/host').collect do |h|
        OVIRT::Host::new(self, h)
      end
    end

    def storagedomain(sd_id, opts={})
      sd = http_get("/storagedomains/%s" % sd_id)
      OVIRT::StorageDomain::new(self, sd.root)
    end
    
    def storagedomains(opts={})
      http_get("/storagedomains").xpath('/storage_domains/storage_domain').collect do |sd|
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