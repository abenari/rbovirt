module OVIRT
  class BaseObject
    attr_accessor :id, :href, :name
    attr_reader :client

    def initialize(client, id, href, name)
      @id, @href, @name = id, href, name
      @client = client
      self
    end

    def parse_version xml
      (xml/'version').first[:major] +"."+ (xml/'version').first[:minor]
    end

    def parse_bool text
      return true if text =~ /^true$/i
      return false if text =~ /^false$/i
      raise ArgumentError.new %Q[The string "#{text}" isn't a valid boolean, it should be "true" or "false"]
    end
  end
end
