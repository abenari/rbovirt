module OVIRT
    # NOTE: Injected file will be available in floppy drive inside
    #       the instance. (Be sure you 'modprobe floppy' on Linux)
    FILEINJECT_PATH = "user-data.txt"

  class VM < BaseObject
    attr_reader :description, :status, :memory, :profile, :display, :host, :cluster, :template
    attr_reader :storage, :cores, :creation_time, :os, :ips, :vnc, :quota
    attr_accessor :interfaces, :volumes

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
    end

    def running?
      !(@status =~ /down/i) && !(@status =~ /wait_for_launch/i)
    end

    # In oVirt 3.1 a vm can be marked down and not locked while its volumes are locked.
    # This method indicates if it is safe to launch the vm.
    def ready?
      return false unless @status =~ /down/i
      volumes.each do |volume|
        return false if volume.status =~ /locked/i
      end
      true
    end

    def interfaces
      @interfaces ||= @client.vm_interfaces(id)
    end

    def quota
      @quota ||= @client.quota(id)
    end

    def volumes
      @volumes ||= @client.vm_volumes(id)
    end

    def self.ticket options={}
      builder = Nokogiri::XML::Builder.new do
        action_{ ticket_{ expiry_(options[:expiry] || 120) } }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def self.to_xml(opts={})
      builder = Nokogiri::XML::Builder.new do
        vm{
          name_ opts[:name] || "i-#{Time.now.to_i}"
          if opts[:template] && !opts[:template].empty?
            template_ :id => (opts[:template])
          elsif opts[:template_name] && !opts[:template_name].empty?
            template_{ name_(opts[:template_name])}
          else
            template_{name_('Blank')}
          end
          if opts[:quota]
            quota_( :id => opts[:quota])
          end
          if opts[:cluster]
            cluster_( :id => opts[:cluster])
          elsif opts[:cluster_name]
            cluster_{ name_(opts[:cluster_name])}
          end
          type_ opts[:hwp_id] || 'Server'
          if opts[:memory]
              memory opts[:memory]
          end
          if opts[:cores]
             cpu {
               topology( :cores => (opts[:cores] || '1'), :sockets => '1' )
             }
          end
          # os element must not be sent when template is present (RHBZ 1104235)
          if opts[:template].nil? || opts[:template].empty?
            os({:type => opts[:os_type] || 'unassigned' }){
              if(opts[:first_boot_dev] && opts[:first_boot_dev] == 'network')
                boot(:dev=> opts[:boot_dev1] || 'network')
                boot(:dev=> opts[:boot_dev2] || 'hd')
              else
                boot(:dev=> opts[:boot_dev2] || 'hd')
                boot(:dev=> opts[:boot_dev1] || 'network')
              end
              kernel (opts[:os_kernel])
              initrd (opts[:os_initrd])
              cmdline (opts[:os_cmdline])
            }
          end
          display_{
            type_(opts[:display][:type])
          } if opts[:display]
          custom_properties {
            custom_property({
              :name => "floppyinject",
              :value => "#{opts[:fileinject_path] || OVIRT::FILEINJECT_PATH}:#{opts[:user_data]}",
              :regexp => "^([^:]+):(.*)$"})
          } if(opts[:user_data_method] && opts[:user_data_method] == :custom_property)
          payloads {
            payload(:type => 'floppy') {
              file(:name => "#{opts[:fileinject_path] || OVIRT::FILEINJECT_PATH}") { content(Base64::decode64(opts[:user_data])) }
            }
          } if(opts[:user_data_method] && opts[:user_data_method] == :payload)
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue '')
      @status = ((xml/'status').first.text rescue 'unknown')
      @memory = (xml/'memory').first.text
      @profile = (xml/'type').first.text
      @template = Link::new(@client, (xml/'template').first[:id], (xml/'template').first[:href])
      @host = Link::new(@client, (xml/'host').first[:id], (xml/'host').first[:href]) rescue nil
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
      @display = {
        :type => (xml/'display/type').first.text,
        :address => ((xml/'display/address').first.text rescue nil),
        :port => ((xml/'display/port').first.text rescue nil),
        :secure_port => ((xml/'display/secure_port').first.text rescue nil),
        :subject => ((xml/'display/certificate/subject').first.text rescue nil),
        :monitors => (xml/'display/monitors').first.text
      }
      @cores = ((xml/'cpu/topology').first[:cores].to_i * (xml/'cpu/topology').first[:sockets].to_i rescue nil)
      @storage = ((xml/'disks/disk/size').first.text rescue nil)
      @creation_time = (xml/'creation_time').text
      @ips = (xml/'guest_info/ips/ip').map { |ip| ip[:address] }
      @vnc = {
        :address => ((xml/'display/address').first.text rescue "127.0.0.1"),
        :port => ((xml/'display/port').first.text rescue "5890")
      } unless @ip
      @os = {
          :type => (xml/'os').first[:type],
          :boot => (xml/'os/boot').collect {|boot| boot[:dev] }
      }
      @quota = ((xml/'quota').first[:id] rescue nil)

      disks = xml/'disks/disk'
      @volumes = disks.length > 0 ? disks.collect {|disk| OVIRT::Volume::new(@client, disk)} : nil

      interfaces = xml/'nics/nic'
      @interfaces = interfaces.length > 0 ? interfaces.collect {|nic| OVIRT::Interface::new(@client, nic)} : nil
    end

  end
end
