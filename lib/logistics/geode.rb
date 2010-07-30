module Logistics
  #
  # A remote gem installer that is role aware. Reads a configuration file from config/gems.json
  class Geode
    attr_accessor :gem_list, :roles, :server
  
    include ManagedSSH
  
    def initialize roles, server = "*"
      self.roles = ["*"] + (roles.is_a?(Array) ? roles : [roles])
      self.server = server
      load_gem_configuration
    end
  
    def load_gem_configuration roles = self.roles, server = self.server
      data = File.read "#{Logistics.config_path}/gems.json"
      data = JSON.parse data
      gems = roles.inject([]) do |list, role|
        list += data[ role ] || []
        list
      end
      gems += data[ server ] if data[ server ]
      self.gem_list = gems.uniq.sort.join " "
    end
  
    def gem_list
      @gem_list || ""
    end
  
    def install!
      ssh = connect_to server
      puts "    * Geode connecting to #{server}, installing #{gem_list}"
      ssh.exec! "gem install #{gem_list}"
    end
  
    #
    # deploys the gems out to the listed servers (via managed SSH).
    # assumes server_data is the json hash from config/servers.json
    # N.B. can only deploy the MOST CURRENT AVAILABLE gems
    def self.deploy_gems_to servers
      servers.each do |(host, data)|
        geo = new data["roles"], host
        next if geo.gem_list == ""
        geo.install!
      end
    end
  
    def self.deploy_gems_to_server_for_role server, role
      geo = new role, server
      return if geo.gem_list == ""
      geo.install!
    end
  
  end
end