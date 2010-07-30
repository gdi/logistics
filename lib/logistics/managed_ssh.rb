require 'net/ssh'

module Logistics
  module ManagedSSH
    @@connections = {}
  
    def connect_to host, user = "root"
      @@connections[host] ||= Net::SSH.start(host, user, :auth_methods => ["publickey"])
    end
  
    def connections
      @@connections
    end
  
    def close_connections
      @@connections.values.each { |ssh| ssh.close }
      @@connections = {}
    end
  end
end