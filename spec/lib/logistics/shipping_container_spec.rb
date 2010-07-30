require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Logistics::ShippingContainer do
  it "should raise a TemplateNotFound error if you give it something it can't find." do
    lambda { Logistics::ShippingContainer.new( 'fnord' ) }.should raise_error(
      Logistics::ShippingContainer::TemplateNotFound,
      "Unable to locate install.mustache in /usr/src/logistics/warehouse/fnord" )
  end
  describe "#render_template" do
    before(:each) do
      File.stub!(:exist?)
      File.stub!(:exist?).with("warehouse/foo/install.mustache").and_return(true)
      File.stub!(:read).and_return(<<-TEMPLATE)
  My mustache is {{mustache_type}} and of {{quality}} quality!
  TEMPLATE
    end
    it "should render the template with mustache" do
      foo = Logistics::ShippingContainer.new("foo")
      foo.stub!(:config).and_return({ "defaults" => { "mustache_type" => "waxed", "quality" => "high" } })
      foo.render_template("install.mustache").strip.should == "My mustache is waxed and of high quality!"
    end
  end
  
  describe "#service?" do
    before(:each) do
      File.stub!(:exist?)
      File.stub!(:exist?).with("warehouse/foo/install.mustache").and_return(true)
      File.stub!(:read).and_return(<<-TEMPLATE)
  My mustache is {{mustache_type}} and of {{quality}} quality!
  TEMPLATE
    end
    it "should return true if this container is going to be set up as a service" do
      sc = Logistics::ShippingContainer.new("foo")
      sc.config = { "service" => true }
      sc.service?.should be_true
    end
  end
end