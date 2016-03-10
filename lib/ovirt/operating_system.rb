module OVIRT
  class OperatingSystem < BaseObject
    attr_reader :description

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').text)
      @description = (xml/'description').text
      self
    end
  end
end
