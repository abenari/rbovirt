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

  # NOTE: Injected file will be available in floppy drive inside
  #       the instance. (Be sure you 'modprobe floppy' on Linux)
  FILEINJECT_PATH = "user-data.txt"

  def self.client(url)
    RestClient::Resource.new(url)
  end

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

    def vms(opts={})
      headers = {
        :accept => "application/xml; detail=disks; detail=nics; detail=hosts"
      }
      headers.merge!(auth_header)
      if opts[:id]
        vm = Client::parse_response(OVIRT::client(@api_entrypoint)["/vms/%s" % opts[:id]].get(headers)).root
        return [] unless current_datacenter.cluster_ids.include?((vm/'cluster').first[:id])
        [ OVIRT::VM::new(self, vm)]
      else
        Client::parse_response(OVIRT::client(@api_entrypoint)["/vms"].get(headers)).xpath('/vms/vm').collect do |vm|
          next unless current_datacenter.cluster_ids.include?((vm/'cluster').first[:id])
          OVIRT::VM::new(self, vm)
        end.compact
      end
    end

    def vm_action(id, action, headers={})
      headers.merge!(auth_header)
      headers.merge!({:accept => 'application/xml'})
      vm = vms(:id => id)
      raise OvirtException::new("Requested VM not found in datacenter #{self.current_datacenter.id}") if vm.empty?
      if action==:delete
        OVIRT::client(@api_entrypoint)["/vms/%s" % id].delete(headers)
      else
        headers.merge!({ :content_type => 'application/xml' })
        begin
          client_response = OVIRT::client(@api_entrypoint)["/vms/%s/%s" % [id, action]].post('<action/>', headers)
        rescue
          if $!.is_a?(RestClient::BadRequest)
            fault = (Nokogiri::XML($!.http_body)/'//fault/detail')
            fault = fault.text.gsub(/\[|\]/, '') if fault
          end
          fault ||= $!.message
          raise OvirtException::new(fault)
        end
        xml_response = Client::parse_response(client_response)

        return false if (xml_response/'action/status').first.text.strip.upcase!="COMPLETE"
      end
      return true
    end

    def api_version
      headers = {
        :content_type => 'application/xml',
        :accept => 'application/xml'
      }
      headers.merge!(auth_header)
      result_xml = Nokogiri::XML(OVIRT::client(@api_entrypoint)["/"].get(headers))
      (result_xml/'/api/product_info/version')
    end

    def api_version?(major)
      api_version.first[:major].strip == major
    end

    def cluster_version?(cluster_id, major)
      headers = {
        :content_type => 'application/xml',
        :accept => 'application/xml'
      }
      headers.merge!(auth_header)
      result_xml = Nokogiri::XML(OVIRT::client(@api_entrypoint)["/clusters/%s" % cluster_id].get(headers))
      (result_xml/'/cluster/version').first[:major].strip == major
    end

    def create_vm(template_name, opts={})
      builder = Nokogiri::XML::Builder.new do
        vm {
          name opts[:name] || "i-#{Time.now.to_i}"
          template_{
            name_(template_name)
          }
          cluster_{
            name_(opts[:cluster_name].nil? ? clusters.first.name : opts[:cluster_name])
          }
          type_ opts[:hwp_id] || 'Server'
          memory opts[:hwp_memory] ? (opts[:hwp_memory].to_i*1024*1024).to_s : (512*1024*1024).to_s
          cpu {
            topology( :cores => (opts[:hwp_cpu] || '1'), :sockets => '1' )
          }
          os{
            boot(:dev=>'network')
            boot(:dev=>'hd')
          }
          display_{
            type_('vnc')
          }
          if opts[:user_data] and not opts[:user_data].empty?
            if api_version?('3') and cluster_version?((opts[:cluster_id] || clusters.first.id), '3')
              custom_properties {
                custom_property({
                  :name => "floppyinject",
                  :value => "#{OVIRT::FILEINJECT_PATH}:#{opts[:user_data]}",
                  :regexp => "^([^:]+):(.*)$"})
              }
            else
              raise OvirtVersionUnsupportedException.new
            end
          end
        }
      end
      headers = opts[:headers] || {}
      headers.merge!({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      })
      headers.merge!(auth_header)
      vm_definition = Nokogiri::XML(builder.to_xml).root.to_s
      begin
        vm = OVIRT::client(@api_entrypoint)["/vms"].post(vm_definition, headers)
      rescue
        if $!.respond_to?(:http_body)
          fault = (Nokogiri::XML($!.http_body)/'/fault/detail').first
          fault = fault.text.gsub(/\[|\]/, '') if fault
        end
        fault ||= $!.message
        raise OvirtException::new(fault)
      end
      OVIRT::VM::new(self, Nokogiri::XML(vm).root)
    end

    def add_disk(vm_id, opts={})
      builder = Nokogiri::XML::Builder.new do
        disk {
          storage_domains{
            storage_domain(:id => self.storagedomains.first.id)
          }
          size(8589934592)
          type_('system')
          bootable('true')
          interface('virtio')
          format_('cow')
          sparse('true')
        }
      end
      headers = opts[:headers] || {}
      headers.merge!({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      })
      headers.merge!(auth_header)
      begin
        OVIRT::client(@api_entrypoint)["/vms/%s/disks" % vm_id].post(Nokogiri::XML(builder.to_xml).root.to_s, headers)
      rescue
        if $!.respond_to?(:http_body)
          fault = (Nokogiri::XML($!.http_body)/'/fault/detail').first
          fault = fault.text.gsub(/\[|\]/, '') if fault
        end
        fault ||= $!.message
        raise OvirtException::new(fault)
      end

    end

    
    def add_nic(vm_id, opts={})
      builder = Nokogiri::XML::Builder.new do
        nic{
          name('eth0')
          network{
            name('ovirtmgmt')
          }
        }
      end
      headers = opts[:headers] || {}
      headers.merge!({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      })
      headers.merge!(auth_header)
      begin
        OVIRT::client(@api_entrypoint)["/vms/%s/nics" % vm_id].post(Nokogiri::XML(builder.to_xml).root.to_s, headers)
      rescue
        if $!.respond_to?(:http_body)
          fault = (Nokogiri::XML($!.http_body)/'/fault/detail').first
          fault = fault.text.gsub(/\[|\]/, '') if fault
        end
        fault ||= $!.message
        raise OvirtException::new(fault)
      end
    end

    def create_template(vm_id, opts={})
      builder = Nokogiri::XML::Builder.new do
        template_ {
          name opts[:name]
          description opts[:description]
          vm(:id => vm_id)
        }
      end
      headers = opts[:headers] || {}
      headers.merge!({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      })
      headers.merge!(auth_header)
      template = OVIRT::client(@api_entrypoint)["/templates"].post(Nokogiri::XML(builder.to_xml).root.to_s, headers)
      OVIRT::Template::new(self, Nokogiri::XML(template).root)
    end

    def destroy_template(id, headers={})
      headers.merge!({
        :content_type => 'application/xml',
        :accept => 'application/xml',
      })
      tmpl = template(id)
      raise OvirtException::new("Requested VM not found in datacenter #{self.current_datacenter.id}") unless tmpl
      headers.merge!(auth_header)
      OVIRT::client(@api_entrypoint)["/templates/%s" % id].delete(headers)
      return true
    end

    def templates(opts={})
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      templates = OVIRT::client(@api_entrypoint)["/templates"].get(headers)
      Client::parse_response(  templates).xpath('/templates/template').collect do |t|
        next unless current_datacenter.cluster_ids.include?((t/'cluster').first[:id])
        OVIRT::Template::new(self, t)
      end.compact
    end

    def template(template_id)
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      template = OVIRT::client(@api_entrypoint)["/templates/%s" % template_id].get(headers)
      OVIRT::Template::new(self, Client::parse_response(template).root)
    end

    def datacenters(opts={})
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      datacenters = OVIRT::client(@api_entrypoint)["/datacenters"].get(headers)
      Client::parse_response(datacenters).xpath('/data_centers/data_center').collect do |dc|
        OVIRT::DataCenter::new(self, dc)
      end
    end

    def clusters
      current_datacenter.clusters
    end

    def cluster(cluster_id)
      current_datacenter.cluster(cluster_id)
    end

    def current_datacenter
      @current_datacenter ||= self.datacenter_id ? datacenter(self.datacenter_id) : datacenters.first
    end

    def datacenter(datacenter_id)
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      datacenter = OVIRT::client(@api_entrypoint)["/datacenters/%s" % datacenter_id].get(headers)
      OVIRT::DataCenter::new(self, Client::parse_response(datacenter).root)
    end

    def hosts(opts={})
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      if opts[:id]
        vm = Client::parse_response(OVIRT::client(@api_entrypoint)["/hosts/%s" % opts[:id]].get(headers)).root
        [ OVIRT::Host::new(self, vm)]
      else
        Client::parse_response(OVIRT::client(@api_entrypoint)["/hosts"].get(headers)).xpath('/hosts/host').collect do |vm|
          OVIRT::Host::new(self, vm)
        end
      end
    end

    def storagedomains(opts={})
      headers = {
        :accept => "application/xml"
      }
      headers.merge!(auth_header)
      if opts[:id]
        vm = Client::parse_response(OVIRT::client(@api_entrypoint)["/storagedomains/%s" % opts[:id]].get(headers)).root
        [ OVIRT::StorageDomain::new(self, vm)]
      else
        Client::parse_response(OVIRT::client(@api_entrypoint)["/storagedomains"].get(headers)).xpath('/storage_domains/storage_domain').collect do |vm|
          OVIRT::StorageDomain::new(self, vm)
        end
      end
    end

    def auth_header
      # As RDOC says this is the function for strict_encode64:
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