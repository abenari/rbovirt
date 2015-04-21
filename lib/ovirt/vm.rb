module OVIRT
    # NOTE: Injected file will be available in floppy drive inside
    #       the instance. (Be sure you 'modprobe floppy' on Linux)
    FILEINJECT_PATH = "user-data.txt"

  class VM < BaseObject
    attr_reader :description, :status, :memory, :profile, :display, :host, :cluster, :template
    attr_reader :storage, :cores, :creation_time, :os, :ha, :ha_priority, :ips, :vnc, :quota, :clone
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
          if !opts[:ha].nil? || !opts[:ha_priority].nil?
            high_availability_{
              enabled_(opts[:ha]) unless opts[:ha].nil?
              priority_(opts[:ha_priority]) unless opts[:ha_priority].nil?
            }
          end
          disks_ { clone_(opts[:clone]) } if opts[:clone]
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
          payloads {
            payload(:type => 'floppy') {
              files {
                file {
                  name_ "#{opts[:fileinject_path] || OVIRT::FILEINJECT_PATH}"
                  content Base64::decode64(opts[:user_data])
                }
              }
            }
          } if(opts[:user_data_method] && opts[:user_data_method] == :payload_v3_3)
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    def self.cloudinit(opts={})
      hostname            = opts[:hostname]
      ip                  = opts[:ip]
      netmask             = opts[:netmask]
      dns                 = opts[:dns]
      gateway             = opts[:gateway]
      domain              = opts[:domain]
      nicname             = opts[:nicname]
      user                = opts[:user] || 'root'
      password            = opts[:password]
      ssh_authorized_keys = opts[:ssh_authorized_keys]
      fileslist           = opts[:files]
      runcmd              = opts[:runcmd]
      extracmd            = nil 
      unless opts[:phone_home].nil?
        phone_home = \
        "phone_home:\n" \
        "  url: #{opts[:phone_home]['url']}\n" \
        "  post: #{opts[:phone_home]['post']}\n"
        extracmd   = phone_home
      end
      cmdlist             = 'runcmd:'
      unless runcmd.nil?
        runcmd.each do |cmd|
          cmdlist = \
	  "#{cmdlist}\n" \
          "- #{cmd}\n"
        end
        if extracmd.nil?
          extracmd = cmdlist
        else
          extracmd = extracmd +cmdlist
        end
      end
      builder   = Nokogiri::XML::Builder.new do
        action {
          vm {
            initialization {
              unless runcmd.nil?
                custom_script cmdlist
              end
              unless phone_home.nil?
                custom_script phone_home
              end
              cloud_init {
                unless hostname.nil?
                  host { address hostname  }
                end
                unless password.nil?
                  users { 
                    user {  
                      user_name user
                      password password
                    }
                  }
                end
                unless ssh_authorized_keys.nil?
                  authorized_keys {
                    authorized_key {
                      user { user_name user }
                      ssh_authorized_keys.each do |sshkey|
                        key sshkey    
                      end
                    }
                  }
                end
                network_configuration { 
                  unless nicname.nil?
                    nics {
                      nic {
	                name_ nicname
                        unless ip.nil? || netmask.nil? || gateway.nil?
                          network { ip(:'address'=> ip , :'netmask'=> netmask, :'gateway'=> gateway ) }
                          boot_protocol 'STATIC'
                          on_boot 'true'
                        end 
                      }
                    } 
                  end
                  dns { 
                    unless dns.nil? 
                      servers {
                        dns.each do |dnsentry|
                          host {  address dnsentry }
                        end
                      }
                    end
                    unless domain.nil? 
                      search_domains { host {  address domain }}
                    end
                  }
                }
              regenerate_ssh_keys 'true'
              files {
                unless extracmd.nil?
                  file {
                    name_   'ignored'
                    content extracmd
                    type    'PLAINTEXT'
                   }
                end
                unless fileslist.nil?
                  fileslist.each do |fileentry|
                    file {
                      name_   fileentry['path']
                      content fileentry['content']
                      type    'PLAINTEXT'
                    }
                  end
                end
              }
             }
            }
          }
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_xml
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
      @ha = ((xml/'high_availability/enabled').first.text rescue nil)
      @ha_priority = ((xml/'high_availability/priority').first.text rescue nil)
      @quota = ((xml/'quota').first[:id] rescue nil)

      disks = xml/'disks/disk'
      @volumes = disks.length > 0 ? disks.collect {|disk| OVIRT::Volume::new(@client, disk)} : nil

      interfaces = xml/'nics/nic'
      @interfaces = interfaces.length > 0 ? interfaces.collect {|nic| OVIRT::Interface::new(@client, nic)} : nil

      @clone = ((xml/'disks/clone').first.text rescue nil)
    end

  end
end

