require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Basic Instance type life cycle" do
  before(:all) do
    setup_client
  end

  it "test_should_return_instance_types" do
    @client.instance_types
  end

  it "test_should_return_an_instance_type" do
    @instance_type = @client.instance_types.first
    @client.instance_type(@instance_type.id).id.should eql(@instance_type.id)
  end
end
