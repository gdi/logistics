module Logistics
  #
  # Takes a set of ShippingContainers and delivers them to a host
  class DeliveryTruck
    include ManagedSSH
  
    attr_accessor :host, :containers
  
    def initialize host, *containers
      self.host = host
      self.containers = containers
    end
    
    def self.deliver_packages_to_server server, *packages
      truck = new server, *packages
      truck.make_delivery
    end
    
    def self.reconfigure_package_on_server server, package
      truck = new server, package
      truck.reconfigure
    end
  
    def comms
      connect_to host
    end
  
    def upload_files containers = self.containers, order = "before"
      containers.each do |container|
        container.file_manifest.each do |file_spec|
          local  = file_spec["local"]
          remote = file_spec["remote"]
          timing = file_spec["when"] || "before"
          next unless timing == order
        
          local_path = File.join( container.base_path, "files", local )
          if local =~ /mustache$/ # it's a template, render it!
            rendered = Mustache.render File.read(local_path),
                                       container.template_context( self.host )
            local_path = StringIO.new rendered
          end
          puts "      * Uploading #{local_path} to #{host}:#{remote}"
          
          begin
            comms.sftp.upload! local_path, remote
          rescue => e
            puts "      * ERROR! Couldn't upload file beacuse #{e}: #{e.message}"
          end
        end
      end
    end
  
    def upload_prerequisites containers = self.containers
      upload_files containers, "before"
    end
  
    def upload_configurations containers = self.containers
      upload_files containers, "after"
    end
  
    def unpack containers = self.containers
      containers.each do |container|
        script = container.generate_installer_for self.host
        upload_and_run self.host, container.package_name, "install", script
      end
    end
  
    def install_services
      containers.each do |container|
        if container.service?
          puts "    * configuring service #{container.package_name} on #{host}"
          ServiceTechnician.install container, host
        end
      end
    end
    
    def upload_and_run host, package_name, script_name, script
      puts "    * uploading /tmp/#{package_name}.#{script_name}.sh to #{host}"
      begin
        comms.sftp.upload! StringIO.new( script ),
                         "/tmp/#{package_name}.#{script_name}.sh"
      rescue => e
        puts "      * ERROR! Couldn't upload installer beacuse #{e}: #{e.message} ABORTING!"
        return
      end
      
      puts "    * executing /tmp/#{package_name}.#{script_name}.sh on #{host}"
      begin
        comms.exec! "chmod +x /tmp/#{package_name}.#{script_name}.sh"
        comms.exec! "/tmp/#{package_name}.#{script_name}.sh"
      rescue => e
        puts "      * ERROR! Couldn't run /tmp/#{package_name}.#{script_name} because #{e}: #{e.message} ABORTING!"
      end
    end
  
    #
    # renders after_install script templates, uploads them, and runs them
    def upload_and_run_after_install_scripts
      containers.each do |container|
        if container.after_install_hooks
          puts "    * configuring post-install hooks on #{host}"
          container.after_install_hooks.each do |hook|
            script = container.render_template "#{hook}.mustache"
            upload_and_run self.host, container.package_name, hook, script
          end
        end
      end
    end
  
    #
    # delivers everything!
    def make_delivery
      upload_prerequisites
      unpack
      install_services
      upload_configurations
      upload_and_run_after_install_scripts
    end
  
    #
    # re-uploads configuration files and reinstalls the services
    def reconfigure_service
      upload_prerequisites
      install_services
      upload_configurations
    end
    
    #
    # just re-uploads files
    def reconfigure
      upload_configurations
      upload_and_run_after_install_scripts
    end
  
  end
end