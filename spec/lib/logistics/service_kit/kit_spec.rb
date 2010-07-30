require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Logistics::ServiceKit::Kit do
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
          
  subject { Logistics::ServiceKit::Kit.new @ssh_proxy, mysql_container, "a-ds-001-1" }
  
  describe "#service_file" do
    it "should default to checking for a file named `service_name`.mustache" do
      subject.service_file.should == "warehouse/mysql/supervise.mustache"
    end
    it "should support providing a customized file name, for whatever reason" do
      subject.stub!(:service_data).and_return({ "file" => "fnordery.rb" })
      subject.service_file.should == "warehouse/mysql/fnordery.rb"
    end
  end
  
  describe "#render_control_script" do
    before(:each) do
      File.stub!(:read).and_return("I'm a happy template!")
    end
    it "should, uh, render the control script" do
      subject.render_control_script.should == "I'm a happy template!"
    end
    it "should hand mustache the container's default variables, if any" do
      subject.stub!(:service_data).
        and_return({ "defaults" => { "whizz" => "fnordery.rb" }})
      Mustache.should_receive(:render).with(
        "I'm a happy template!",
        hash_including({ "whizz" => "fnordery.rb" })
      )
      subject.render_control_script
    end
    it "should include the hostname of the server by default" do
      Mustache.should_receive(:render).with(
        "I'm a happy template!",
        hash_including({ "host" => "a-ds-001-1" })
      )
      subject.render_control_script
    end
    it "should combine the template's default variables with the given ones" do
      subject.stub!(:service_data).
        and_return({ "defaults" => { "whizz" => "fnordery.rb" }})
      Mustache.should_receive(:render).with(
        "I'm a happy template!",
        hash_including({ "whizz" => "fnordery.rb", "instance" => 1 })
      )
      subject.render_control_script({ "instance" => 1})
    end
  end
end