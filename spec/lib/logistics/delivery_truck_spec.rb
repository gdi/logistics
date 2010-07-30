require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Logistics::DeliveryTruck do
  before(:each) do
    Logistics::ManagedSSH.send(:class_variable_set, :@@connections, {})
    @sftp_proxy = mock(Object, :upload! => nil)
    @ssh_proxy = mock(Net::SSH, :exec! => nil)
    @ssh_proxy.stub!(:sftp).and_return(@sftp_proxy)
    Net::SSH.stub!(:start).and_return(@ssh_proxy)
  end
  let(:rvm_container) {
    mock( Logistics::ShippingContainer,
          :file_manifest => [ {"local" => "rvm_bashrc", "remote" => "/tmp/rvm_bashrc"} ],
          :base_path => "warehouse/rvm",
          :package_name => "rvm") }
  let(:mysql_container) {
    mock( Logistics::ShippingContainer,
          :file_manifest => [
            { "local" => "my.cnf", "remote" => "/etc/mysql/my.cnf"},
            { "local" => "grants.sql", "remote" => "/tmp/grants.sql"}
          ],
          :base_path => "warehouse/mysql",
          :package_name => "mysql",
          :service? => true, :service => { "type" => "supervise" },
          :after_install_hooks => ["secure_it"]) }
  let(:git_container) {
    mock( Logistics::ShippingContainer,
          :file_manifest => [],
          :base_path => "warehouse/git",
          :generate_installer_for => "template",
          :service? => false,
          :package_name => "git", :after_install_hooks => nil)
  }
  
  describe "#upload_files" do
    context "with files to be uploaded" do
      it "should upload all of the given containers' files to the given host" do
        truck = Logistics::DeliveryTruck.new "a-ds-001-1", rvm_container, mysql_container
        @sftp_proxy.should_receive(:upload!).
          with("warehouse/rvm/files/rvm_bashrc", "/tmp/rvm_bashrc")
        @sftp_proxy.should_receive(:upload!).
          with("warehouse/mysql/files/my.cnf", "/etc/mysql/my.cnf")
        @sftp_proxy.should_receive(:upload!).
          with("warehouse/mysql/files/grants.sql", "/tmp/grants.sql")
        truck.upload_files
      end
      it "should operate on just a passed-in list of containers, too" do
        truck = Logistics::DeliveryTruck.new "a-ds-001-1", rvm_container
        @sftp_proxy.should_not_receive(:upload!).
          with("warehouse/rvm/files/rvm_bashrc", "/tmp/rvm_bashrc")
        @sftp_proxy.should_receive(:upload!).
          with("warehouse/mysql/files/my.cnf", "/etc/mysql/my.cnf")
        @sftp_proxy.should_receive(:upload!).
          with("warehouse/mysql/files/grants.sql", "/tmp/grants.sql")
        truck.upload_files [mysql_container]
      end
    end
    context "with no files to be uploaded" do
      it "should not upload anything" do
        truck = Logistics::DeliveryTruck.new "a-ds-001-1", git_container
        @sftp_proxy.should_not_receive(:upload!)
        truck.upload_files
      end
    end
  end
  
  describe "#unpack" do
    let(:truck) { Logistics::DeliveryTruck.new "a-ds-001-1", git_container }
    context "for each container" do
      it "should upload the install scripts to /tmp" do
        StringIO.stub!(:new).with("template").and_return "template"
        @sftp_proxy.should_receive(:upload!).with(StringIO.new("template"), "/tmp/git.install.sh")
        truck.unpack [git_container]
      end
      it "should chmod +x the install scripts" do
        @ssh_proxy.should_receive(:exec!).with("chmod +x /tmp/git.install.sh")
        truck.unpack [git_container]
      end
      it "should run the install script" do
        @ssh_proxy.should_receive(:exec!).with("/tmp/git.install.sh")
        truck.unpack [git_container]
      end
    end
  end
  
  describe "#install_services" do
    let(:truck) { Logistics::DeliveryTruck.new "a-ds-001-1", git_container, mysql_container }
    it "should give each container containing a service to the ServiceTechnician" do
      Logistics::ServiceTechnician.should_receive(:install).with(mysql_container, "a-ds-001-1")
      truck.install_services
    end
  end
  
  describe "#reconfigure_service" do
    let(:truck) { Logistics::DeliveryTruck.new "a-ds-001-1", git_container, mysql_container }
    it "should re-upload the files and reinstall the service scripts" do
      truck.should_receive(:upload_files).twice
      truck.should_receive(:install_services)
      truck.reconfigure_service
    end
  end
  
  describe "#reconfigure" do
    let(:truck) { Logistics::DeliveryTruck.new "a-ds-001-1", git_container, mysql_container }
    it "should re-upload the config files and run post-install scripts" do
      truck.should_receive(:upload_configurations)
      truck.should_receive(:upload_and_run_after_install_scripts)
      truck.reconfigure
    end
  end
  
end