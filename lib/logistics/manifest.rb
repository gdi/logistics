module Logistics
  class Manifest
    
    attr_accessor :manifest, :env, :configuration
    
    def initialize config_data, environment = "staging"
      self.env = environment
      load_configuration
      self.manifest = config_data
    end
    
    def self.all_roles environment
      m = new({}, environment)
      m.manifest = { "roles" => m.available_roles }
      m
    end
    
    def self.for_server server, environment
      m = new({}, environment)
      m.add_server server
      m
    end
    
    def available_roles
      self.configuration["packages"].keys - ["*"]
    end
    
    def load_configuration environment = self.env
      conf = {}
      %w(servers gems packages).each do |source|
        conf[source] = JSON.parse( File.read("#{Logistics.config_path}/#{source}.json") )[environment]
      end
      self.configuration = conf
    end
    
    #
    # Converts your data into a list of packages to install on servers.
    # Merges specific server instructions into role instructions.
    #
    # the data should look something like so:
    # { "roles": [...], "servers":
    #   { "*": ["container_1", ...] },
    #   { "specific_server_name": ["container_2", ...] }, ...
    # }
    def manifest= data
      @manifest ||= {}
      return if data.empty?
      (data["roles"] || []).each do |role|
        add_role_to_manifest role
      end
      (data["servers"] || []).each do |(server_name, container_list)|
        if server_name == "*"
          configuration["servers"].keys.each do |real_server|
            add_server_to_manifest_with_containers real_server, container_list
          end
        else
          add_server_to_manifest_with_containers server_name, container_list
        end
      end
    end
    alias_method :items, :manifest
    
    def add_role_to_manifest role
      servers_for_role(role).each do |server|
        @manifest[server] ||= []
        @manifest[server] |= containers_for_role(role)
      end
    end
    
    def remove_role_from_manifest role
      servers_for_role(role).each do |server|
        @manifest[server] ||= []
        @manifest[server] = @manifest[server] - containers_for_role(role)
        if @manifest[server].empty?
          @manifest.delete(server)
        end
      end
    end
    
    def add_server server_name
      base_packages_for_server = configuration["packages"]["*"]
      role_packages = []
      if configuration["servers"][server_name]
        configuration["servers"][server_name]["roles"].each do |role|
          role_packages |= (configuration["packages"][role] || [])
        end
      else
        puts "Server #{server_name} not found! Aborting!"
      end
      package_list = base_packages_for_server | role_packages
      self.manifest = { "servers" => { server_name => package_list } }
    end
    
    def remove_server server_name
      @manifest.delete(server_name)
    end
    
    def servers_for_role role
      if role == "*"
        configuration["servers"].keys
      else
        configuration["servers"].inject([]) do |accum, (name, data)|
          accum << name if data["roles"].include?(role)
          accum
        end
      end
    end
    
    def containers_for_role role
      configuration["packages"][role] || []
    end
    
    def servers_and_roles
      manifest.keys.inject({}) do |accum, hostname|
        accum[hostname] = { "roles" => configuration["servers"][hostname]["roles"] }
        accum
      end
    end
    
    def add_server_to_manifest_with_containers server_name, container_list
      @manifest[server_name] ||= []
      @manifest[server_name] |= container_list
    end
    
  end
end