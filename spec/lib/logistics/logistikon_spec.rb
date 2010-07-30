require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Logistics::Logistikon do
  before(:each) do
    File.stub!(:read).with("config/deployment_orders.json").and_return('{ "primary": { "roles": [ "gem_server" ] } }')
  end
  
  subject { Logistics::Logistikon.new "staging" }
  
  describe "#initialize" do
    it "should read config data from the given file" do
      File.should_receive(:read).with("config/words.json").and_return('{ "primary": [1] }')
      l = Logistics::Logistikon.new("staging", "words.json")
      l.orders.should == { "primary" => [1] }
    end
    it "should have default to looking for 'config/deployment_orders.json'" do
      subject.orders.should == { "primary" => { "roles" => [ "gem_server" ] } }
    end
  end
  
  describe "#roles_from_orders" do
    it "should return a list of all the roles specified in the orders" do
      subject.roles_from_orders.should == ["gem_server"]
    end
  end
  
  describe "#prepare" do
    it "should execute all of the orders" do
      subject.should_receive(:execute).exactly(3).times
      subject.prepare
    end
  end
  
  describe "#execute" do
    it "should simply return immediately if handed nil" do
      subject.execute(nil).should be_nil
    end
    context "with a set of orders" do
      let(:orders) {
        { "roles" => ["gem_server"], "servers" => { "*" => ["configure_rubygems"] } }
      }
      let(:manifest) { mock(Logistics::Manifest) }
      before(:each) do
        Logistics::ShippingManager.stub!(:deliver_from_manifest)
        Logistics::Manifest.stub!(:new).and_return(manifest)
      end
      it "should create a Manifest" do
        Logistics::Manifest.should_receive(:new).with(orders, "staging").and_return(manifest)
        subject.execute orders
      end
      it "should tell the ShippingManager to deliver the manifest" do
        Logistics::ShippingManager.should_receive(:deliver_from_manifest).
          with(manifest)
        subject.execute orders
      end
    end
  end
  
end