require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Logistics::ShippingManager do
  let(:manifest) { Logistics::Manifest.new({ "servers" => { "*" => ["prep", "other_container" ] }}, "test") }
  subject { Logistics::ShippingManager.new manifest }
    
  describe "#manage_deliveries" do
    before(:each) do
      subject.stub!(:handle_delivery)
    end
    it "should handle the delivery of each item in the manifest" do
      subject.should_receive(:handle_delivery).with("a-test-server", ["prep", "other_container" ])
      subject.should_receive(:handle_delivery).with("a-test-web", ["prep", "other_container" ])
      subject.manage_deliveries
    end
  end
  
  describe "#handle_delivery" do
    it "should load a DeliveryTruck for the given server with the given packages" do
      Logistics::DeliveryTruck.should_receive(:deliver_packages_to_server).
        with("a-test-web",  instance_of(Logistics::ShippingContainer),
                            instance_of(Logistics::ShippingContainer) )
      subject.handle_delivery "a-test-web", ["git", "nginx"]
    end
  end
  
  describe ".deliver_from_manifest" do
    it "should create a new instance of itself and manage deliveries" do
      subject.should_receive(:manage_deliveries)
      Logistics::ShippingManager.stub!(:new).and_return(subject)
      Logistics::ShippingManager.deliver_from_manifest manifest
    end
  end
  
end