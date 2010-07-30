module Logistics
  #
  # Logistikon. The deployment machine. It attempts to provide a reasonable
  #   order of operations for the rest of the logistics mechanisms.
  #
  # It acquires its orders from config/deployment_orders.json, executing the role
  # or container setup as specified in each section, in order (primary, secondary,
  # tertiary).
  class Logistikon
    attr_accessor :orders, :env
    
    def initialize env = "test", config_file = "deployment_orders.json"
      self.orders = JSON.parse File.read( File.join(Logistics.config_path, config_file) )
      self.env = env
    end
    
    def prepare
      execute orders["primary"]
      execute orders["secondary"]
      execute orders["tertiary"]
    end
    
    def roles_from_orders
      orders.inject([]) do |role_list, (priority, data)|
        if data["roles"]
          role_list |= data["roles"]
        end
        role_list
      end
    end
    
    #
    # orders are json-representations of Manifests, so... create the manifest
    # and hand it to the ShippingManager
    def execute the_orders
      return if the_orders.nil?
      local_scripts = the_orders.delete("local")
      if local_scripts
        run_local_scripts local_scripts
      end
      unless the_orders.nil? || the_orders.empty?
        m = Manifest.new the_orders, self.env
        manager = ShippingManager.deliver_from_manifest m
      end
    end
    
    def run_local_scripts the_scripts
      the_scripts.each do |script|
        puts "  * Running local script #{script}"
        `#{script}`
      end
    end
    
    #
    # the * role is there to specify a standard set of base packages every server
    # depends on.
    def install_base_packages
      execute({ "roles" => ["*"] })
    end
    
    #
    # installs all of the defined roles
    def install_roles skip_prep_roles = true
      m = Manifest.all_roles self.env
      if skip_prep_roles
        roles_from_orders.each { |role| m.remove_role_from_manifest(role) }
      end
      manager = ShippingManager.deliver_from_manifest m
      Geode.deploy_gems_to m.servers_and_roles
    end
    
    def inception!
      install_base_packages
      prepare
      install_roles
    end
    
  end
end