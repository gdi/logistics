module Logistics
  module ServiceKit
    #
    # Abstract base class Kit, please subclass for great justice.
    class Kit
      attr_accessor :ssh, :package_name, :service_data, :base_path, :host
    
      def initialize ssh, container, host
        self.ssh = ssh
        self.package_name = container.package_name
        self.service_data = container.service
        self.base_path = container.base_path
        self.host = host
      end
    
      def configure_service!
        before_install
        install
        after_install
      end
    
      #
      # implement these in your subclass.
      def before_install; end
      def after_install; end
      def install; end
    
      # the path to the service's control script template
      def service_file
        @service_file ||= File.join( self.base_path, self.service_data["file"] || "#{self.service_data["type"]}.mustache" )
      end
    
      # determines the default template parameters, as loaded from config.json
      # the global defaults are merged with any host-specific definitions found
      def template_context
        defaults = self.service_data["defaults"] || {}
        specific_data = self.service_data[self.host] || {}
        defaults.merge( specific_data ).merge( { "host" => self.host } )
      end
    
      #
      # renders the service file as a mustache template.
      # you can supply variables to the template via the config.json file
      #   e.g. { "service": { "defaults": { ... }}}
      # or handed in directly to this method, or both.
      def render_control_script template_variables = {}
        Mustache.render(
          File.read(self.service_file),
          template_context.merge(template_variables) )
      end
    end
  end
end

require "logistics/service_kit/supervise"