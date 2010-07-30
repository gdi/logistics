module Logistics
  #
  # co-ordinates DeliveryTrucks and Geode deployments
  class ShippingManager
    attr_accessor :manifest
  
    def initialize manifest
      self.manifest = manifest
    end
  
    class << self
      def deliver_from_manifest manifest
        sm = new(manifest)
        sm.manage_deliveries
      end
    end
    
    def manage_deliveries
      puts "  * Shipping Manager is managing our manifest"
      manifest.items.each do |(server, packages)|
        puts "    * Managing delivery of #{packages.join(", ")} to #{server}"
        handle_delivery server, packages
      end
    end
  
    def handle_delivery server, packages
      containers = packages.map { |name| ShippingContainer.new name }
      DeliveryTruck.deliver_packages_to_server server, *containers
    end
  
  end
end