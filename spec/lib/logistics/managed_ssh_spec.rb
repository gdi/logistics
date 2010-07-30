require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

class A
  include Logistics::ManagedSSH
end

class B
  include Logistics::ManagedSSH
end

describe Logistics::ManagedSSH do
  before :each do
    Net::SSH.stub!(:start).and_return(mock(Object, :close => nil))
  end
  it "should pool connections across classes" do
    a = A.new
    b = B.new
    a.connect_to "sparky"
    b.connections.keys.should include("sparky")
  end
end