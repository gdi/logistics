logistics_path = File.join(File.dirname(__FILE__),'..','lib')
$LOAD_PATH.unshift( logistics_path ) unless $LOAD_PATH.include?( logistics_path )

module Logistics
  def self.warehouse_path= path
    @warehouse_path = path
  end
  def self.warehouse_path
    @warehouse_path || "warehouse"
  end
  def self.config_path= path
    @config_path = path
  end
  def self.config_path
    @config_path || "config"
  end
end

require 'yajl/json_gem'
require 'mustache'
require "logistics/managed_ssh"
require "logistics/key_master"
require "logistics/manifest"
require "logistics/geode"
require "logistics/shipping_container"
require "logistics/delivery_truck"
require "logistics/service_technician"
require "logistics/shipping_manager"
require "logistics/logistikon"