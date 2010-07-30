require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Logistics::ServiceKit::Supervise do
  before :each do
    Logistics::ManagedSSH.send(:class_variable_set, :@@connections, {})
    @sftp_proxy = mock(Object, :upload! => nil)
    @ssh_proxy = mock(Net::SSH, :exec! => nil)
    @ssh_proxy.stub!(:sftp).and_return(@sftp_proxy)
    Net::SSH.stub!(:start).and_return(@ssh_proxy)
  end
  let(:single_mysql) {
    mock( Logistics::ShippingContainer,
          :file_manifest => [
            {"my.cnf" => "/etc/mysql/my.cnf"},
            {"grants.sql" => "/tmp/grants.sql"}
          ],
          :base_path => "warehouse/mysql",
          :package_name => "mysql", :options => {},
          :service? => true, :service => { "type" => "supervise" }) }
  let(:multi_mysql) {
    mock( Logistics::ShippingContainer,
          :base_path => "warehouse/mysql",
          :package_name => "mysql", :options => {},
          :service? => true, 
          :service => {
            "type" => "supervise",
            "instances" => 4,
            "start_at" => 4000
          } )}

  let(:single_instanced_service) {
    Logistics::ServiceKit::Supervise.new @ssh_proxy, single_mysql, "a-ds-001-1" }
  let(:multi_instanced_service) {
    Logistics::ServiceKit::Supervise.new @ssh_proxy, multi_mysql, "a-ds-001-1" }
  
  describe "#before_install" do
    context "with a single instance" do
      subject { single_instanced_service }
      it "should mkdir -p a /service/`service_name` directory" do
        @ssh_proxy.should_receive(:exec!).with("mkdir -p /service/mysql")
        single_instanced_service.before_install
      end
    end
    context "with multiple instances" do
      subject { multi_instanced_service }
      it "should create a collection of /service/`service_name_instance` dirs" do
        @ssh_proxy.should_receive(:exec!).with("mkdir -p /service/mysql_1")
        @ssh_proxy.should_receive(:exec!).with("mkdir -p /service/mysql_2")
        @ssh_proxy.should_receive(:exec!).with("mkdir -p /service/mysql_3")
        @ssh_proxy.should_receive(:exec!).with("mkdir -p /service/mysql_4")
        multi_instanced_service.before_install
      end
    end
    
  end
  
  describe "#after_install" do
    context "with a single instance" do
      subject { single_instanced_service }
      it "should chmod the /service/`service_name`/run script" do
        @ssh_proxy.should_receive(:exec!).with("chmod 755 /service/mysql/run")
        single_instanced_service.after_install
      end
    end
    context "with multiple instances" do
      subject { multi_instanced_service }
      it "should chmod the collection of /service/`service_name_instance` scripts" do
        @ssh_proxy.should_receive(:exec!).with("chmod 755 /service/mysql_1/run")
        @ssh_proxy.should_receive(:exec!).with("chmod 755 /service/mysql_2/run")
        @ssh_proxy.should_receive(:exec!).with("chmod 755 /service/mysql_3/run")
        @ssh_proxy.should_receive(:exec!).with("chmod 755 /service/mysql_4/run")
        multi_instanced_service.after_install
      end
    end
    
  end
  
  describe "#install" do
    context "with a single instance" do
      before(:each) do
        File.stub!(:read).and_return("I'm a happy template!")
      end
      subject { single_instanced_service }
      it "should upload the script to one place" do
        @sftp_proxy.should_receive(:upload!).with(
          instance_of(StringIO),
          "/service/mysql/run"
        )
        single_instanced_service.install
      end
    end
    context "with multiple instances" do
      before(:each) do
        File.stub!(:read).and_return("I'm template number {{instance}}!")
      end
      subject { multi_instanced_service }
      it "should chmod the collection of /service/`service_name_instance` scripts" do
        @sftp_proxy.should_receive(:upload!).with(
          instance_of(StringIO),
          "/service/mysql_1/run"
        )
        @sftp_proxy.should_receive(:upload!).with(
          instance_of(StringIO),
          "/service/mysql_2/run"
        )
        @sftp_proxy.should_receive(:upload!).with(
          instance_of(StringIO),
          "/service/mysql_3/run"
        )
        @sftp_proxy.should_receive(:upload!).with(
          instance_of(StringIO),
          "/service/mysql_4/run"
        )
        multi_instanced_service.install
      end
    end
    
  end
  
end