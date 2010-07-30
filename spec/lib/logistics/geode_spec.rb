require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

CONFIG_FILE = {
  "data_store" => [ "super_cluster", "data_store_server" ],
  "hosted_services_portal" => [ "rails", "delayed_job" ],
  "chef-client" => [ "chef" ],
  "a-ds-001-1.devel.greenviewdata.com" => [ "bonus_gem" ],
  "redundancy_dept" => [ "rails" ]
}.to_json

describe Logistics::Geode do
  subject { Logistics::Geode.new("data_store") }
  before(:each) do
    Logistics::ManagedSSH.send(:class_variable_set, :@@connections, {})
    File.stub!(:read).with("config/gems.json").and_return(CONFIG_FILE)
  end
  
  describe ".deploy_gems_to" do
    before(:each) do
      @ssh_proxy = mock(Net::SSH, :exec! => nil)
      Net::SSH.stub(:start).and_return(@ssh_proxy)
      @servers = {
        "a-ds-001-1.devel.greenviewdata.com" => {
          "roles" => ["data_store", "chef-client"]
        },
        "a-ds-001-2.devel.greenviewdata.com" => {
          "roles" => ["data_store", "chef-client"]
        },
        "a-web-001.devel.greenviewdata.com" => {
          "roles" => ["hosted_services_portal", "chef-client"]
        },
        "a-solr-001.devel.greenviewdata.com" => {
          "roles" => ["indexer", "chef-client"]
        }
      }
    end
    it "should attempt to connect to each given server" do
      @servers.keys.each do |host|
        Net::SSH.should_receive(:start).with(host, "root", :auth_methods => ["publickey"]).and_return(@ssh_proxy)
      end
      Logistics::Geode.deploy_gems_to @servers
    end
    it "should execute some gem install action on each server" do
      @servers.each do |host, data|
        @ssh_proxy.should_receive(:exec!).with( "gem install #{subject.load_gem_configuration( data["roles"], host )}" )
      end
      Logistics::Geode.deploy_gems_to @servers
    end
  end
  
  describe "#load_gem_configuration" do
    it "should read a json-formatted configuration file" do
      File.should_receive(:read).and_return(CONFIG_FILE)
      subject
    end
    it "should grab a list of gems for the given role" do
      gems = subject.load_gem_configuration ["data_store"], "*"
      gems.should == [ "super_cluster", "data_store_server" ].sort.join(" ")
    end
    it "should include any server-specific gems for the given server" do
      gems = subject.load_gem_configuration ["data_store"], "a-ds-001-1.devel.greenviewdata.com"
      gems.should == [ "super_cluster", "data_store_server", "bonus_gem" ].sort.join(" ")
    end
    it "should grab a list of gems for all the roles" do
      gems = subject.load_gem_configuration ["data_store", "chef-client"], "*"
      gems.should == [ "super_cluster", "data_store_server", "chef" ].sort.join(" ")
    end
    it "should only return unique gem names" do
      gems = subject.load_gem_configuration ["hosted_services_portal"], "redundancy_dept"
      gems.should == [ "delayed_job", "rails" ].sort.join(" ")
    end
  end
  
  describe "#gem_list" do
    it "should return an empty string if there are no matching gems" do
      g = Logistics::Geode.new("foo")
      g.gem_list.should == ""
    end
  end
end