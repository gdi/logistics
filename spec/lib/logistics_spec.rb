require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Logistics do
  describe ".warehouse_path" do
    it "should default to 'warehouse'" do
      Logistics.warehouse_path.should == "warehouse"
    end
  end
  describe ".config_path" do
    it "should default to 'config'" do
      Logistics.config_path.should == "config"
    end
  end
end