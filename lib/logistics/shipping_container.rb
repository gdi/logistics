module Logistics
  #
  # thin wrapper around mustache, for rendering templates. Intended for use with the package installer, e.g.:
  #     box = ShippingContainer.new( 'git', { :git_version => '1.7.1' } ) # => looks up "../warehouse/git.mustache"
  #     script = box.render # => renders the template. Wrap it in a StringIO, upload it, and go!
  class ShippingContainer
    class TemplateNotFound < StandardError; end
    attr_accessor :package_name, :installer, :config
  
    def initialize package_name
      self.package_name = package_name
      self.config = File.exist?( File.join( base_path, "config.json" ) ) ?
        JSON.parse( File.read( File.join( base_path, "config.json" ) ) ) : {}
    
      unless File.exist? File.join( base_path, "install.mustache" )
        raise TemplateNotFound.new("Unable to locate install.mustache in #{File.expand_path(base_path)}")
      end
    end
  
    def render_template template, context = self.config["defaults"]
      Mustache.render File.read( File.join( base_path, template ) ), context
    end
  
    def generate_installer_for host
      render_template "install.mustache", template_context(host)
    end
  
    # determines the default template parameters, as loaded from config.json
    # the global defaults are merged with any host-specific definitions found
    def template_context host
      defaults      = self.config["defaults"] || {}
      specific_data = self.config[host] || {}
      defaults.merge( specific_data ).merge( { "host" => host } )
    end
  
    def base_path
      @base_path ||= File.join( Logistics.warehouse_path, package_name )
    end
  
    def file_manifest
      self.config["files"] || []
    end
  
    def service
      self.config["service"]
    end
  
    def service?
      !service.nil?
    end
  
    def after_install_hooks
      self.config["after_install"]
    end
  end
end