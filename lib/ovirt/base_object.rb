module OVIRT
  class BaseObject
    attr_accessor :id, :href, :name
    attr_reader :client

    def initialize(client, id, href, name)
      @id, @href, @name = id, href, name
      @client = client
      self
    end
  end
end