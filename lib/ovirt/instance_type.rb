module OVIRT
  # Instance types are added to oVirt 3.5 and have been updated in oVirt 3.6
  class InstanceType < BaseObject
    # Common attributes to all oVirt version supported at this time
    attr_reader :name, :description, :memory, :cores, :os, :creation_time
    attr_reader :ha, :ha_priority, :display, :usb, :migration_downtime

    # oVirt 3.5 attributes
    attr_reader :type, :status, :cpu_shares, :boot_menu, :origin, :stateless
    attr_reader :delete_protected, :sso, :timezone

    # oVirt 3.6 attributes
    attr_reader :migration, :io_threads, :memory_guaranteed

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    private
    def parse_xml_attributes!(xml)
      # Common attributes
      @description = ((xml/'description').first.text rescue '')
      @memory = (xml/'memory').first.text
      @cores = (xml/'cpu/topology').first[:cores].to_i
      @sockets = (xml/'cpu/topology').first[:sockets].to_i
      @os = {
          :type => (xml/'os').first[:type],
          :boot => (xml/'os/boot').collect {|boot| boot[:dev] }
      }
      @creation_time = (xml/'creation_time').text
      @ha = parse_bool((xml/'high_availability/enabled').first.text)
      @ha_priority = ((xml/'high_availability/priority').first.text rescue nil)
      @display = {
        :type => (xml/'display/type').first.text,
        :monitors => (xml/'display/monitors').first.text,
        :single_qxl_pci => parse_bool((xml/'display/single_qxl_pci').first.text),
        :smartcard_enabled => parse_bool((xml/'display/smartcard_enabled').first.text),

      }
      @usb = parse_bool((xml/'usb/enabled').first.text)
      @migration_downtime = ((xml/'migration_downtime').first.text)

      # oVirt 3.5 attributes
      @type = ((xml/'type').first.text rescue nil)
      @status = ((xml/'status').first.text rescue nil)
      @cpu_shares = (((xml/'cpu_shares').first.text) rescue nil)
      potential_bool = ((xml/'bios/boot_menu/enabled').first.text rescue nil)
      @boot_menu = potential_bool.nil? ? nil : parse_bool(potential_bool)
      @origin = ((xml/'origin').text rescue nil)
      potential_bool = ((xml/'stateless').first.text rescue nil)
      @stateless = potential_bool.nil? ? nil : parse_bool(potential_bool)
      potential_bool = ((xml/'delete_protected').first.text rescue nil)
      @delete_protected = potential_bool.nil? ? nil : parse_bool(potential_bool)
      #@sso = ((xml/'sso/methods').first.text rescue nil)
      @timezone = ((xml/'timezone').first.text rescue nil)
      potential_bool = ((xml/'display/allow_override').first.text rescue nil)
      @display[:allow_override] = potential_bool.nil? ? nil : parse_bool(potential_bool)
      potential_bool = ((xml/'display/file_transfer_enabled').first.text rescue nil)
      @display[:file_transfer_enabled] = potential_bool.nil? ? nil : parse_bool(potential_bool)
      potential_bool = ((xml/'display/copy_paste_enabled').first.text rescue nil)
      @display[:copy_paste_enabled] = potential_bool.nil? ? nil : parse_bool(potential_bool)

      # oVirt 3.6 attributes
      @migration = {
        :auto_converge => ((xml/'migration/auto_converge').first.text rescue nil),
        :compressed => ((xml/'migration/compressed').first.text rescue nil)
      }
      @io_threads = ((xml/'io/threads').first.text rescue nil)
      @memory_guaranteed = ((xml/'memory_policy/guaranteed').first.text rescue nil)
    end
  end
end
