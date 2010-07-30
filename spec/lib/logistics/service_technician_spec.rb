require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Logistics::ServiceKit
  class Test < Kit
  end
end

describe Logistics::ServiceTechnician do
  before :each do
    Logistics::ManagedSSH.send(:class_variable_set, :@@connections, {})
    @sftp_proxy = mock(Object, :upload! => nil)
    @ssh_proxy = mock(Net::SSH, :exec! => nil)
    @ssh_proxy.stub!(:sftp).and_return(@sftp_proxy)
    Net::SSH.stub!(:start).and_return(@ssh_proxy)
  end
  let(:mysql_container) {
    mock( Logistics::ShippingContainer,
          :file_manifest => [
            {"my.cnf" => "/etc/mysql/my.cnf"},
            {"grants.sql" => "/tmp/grants.sql"}
          ],
          :base_path => "warehouse/mysql",
          :package_name => "mysql", :options => {},
          :service? => true, :service => { "type" => "supervise" }) }
  
  describe ".install" do
    it "should create a new object" do
      Logistics::ServiceTechnician.should_receive(:new).with(mysql_container, "a-ds-001-1").
        and_return(mock(Logistics::ServiceTechnician, :install => nil))
      Logistics::ServiceTechnician.install mysql_container, "a-ds-001-1"
    end
    it "should call #install on the new object" do
      new_tech = mock(Logistics::ServiceTechnician)
      Logistics::ServiceTechnician.stub(:new).with(mysql_container, "a-ds-001-1").and_return( new_tech )
      new_tech.should_receive(:install)
      Logistics::ServiceTechnician.install mysql_container, "a-ds-001-1"
    end
  end
  
  subject { Logistics::ServiceTechnician.new mysql_container, "a-ds-001-1" }
  
  describe "initialization" do
    it "should set the service_type correctly" do
      subject.service_type.should == "supervise"
    end
  end
  
  describe "#install" do
    before(:each) do
      @mock_kit = Logistics::ServiceKit::Test.new(nil, mysql_container, "a-ds-001-1")
    end
    it "should instantiate a new ServiceKit" do
      Logistics::ServiceKit::Test.should_receive(:new).with(anything, mysql_container, "a-ds-001-1").and_return(@mock_kit)
      mysql_container.stub!(:service).and_return({ "type" => "test" })
      subject.install
    end
    it "should instruct the kit to configure the service" do
      Logistics::ServiceKit::Test.stub!(:new).with(anything, mysql_container, "a-ds-001-1").and_return(@mock_kit)
      mysql_container.stub!(:service).and_return({ "type" => "test" })
      @mock_kit.should_receive(:configure_service!)
      subject.install
    end
  end
  
end