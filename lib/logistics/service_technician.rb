require 'logistics/service_kit/kit'

module Logistics
  #
  # Configures the host to run the contents of the given container as a service
  class ServiceTechnician
    def self.install container, host
      tech = new container, host
      tech.install
    end
  
    include ManagedSSH
  
    attr_accessor :container, :host, :service, :base_path
  
    def initialize container, host
      self.container = container
      self.host = host
      self.service = container.service
    end
  
    def service_type
      service["type"]
    end
  
    def comms
      connect_to host
    end
  
    # load the appropriate installer kit based on the service_type
    # run the installer kit
    def install
      kit_klass = ServiceKit.const_get self.service_type.capitalize
      kit = kit_klass.new comms, container, host
      kit.configure_service!
    end
  end
end