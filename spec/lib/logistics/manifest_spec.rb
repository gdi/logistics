require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Logistics::Manifest do
  subject { Logistics::Manifest.new({}, "test") }
  describe "#load_configuration" do
    it "should set an attribute called :configuration" do
      subject.load_configuration "staging"
      subject.configuration.should_not be_empty
    end
    it "should set up a three-headed hash" do
      conf = subject.load_configuration "staging"
      conf.keys.sort.should == ["gems", "packages", "servers"]
    end
  end
  
  describe "#add_role_to_manifest" do
    it "should add the role's servers and packages to the manifest" do
      subject.instance_variable_set(:@manifest, {})
      subject.add_role_to_manifest "test_bed"
      subject.items.should == { "a-test-server"=>["package_a", "package_b"] }
    end
  end
  
  describe "#remove_role_from_manifest" do
    it "should remove the role's servers and packages from the manifest" do
      subject.remove_role_from_manifest "test_bed"
      subject.items.should == {}
    end
  end

end