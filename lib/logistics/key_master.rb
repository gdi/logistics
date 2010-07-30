require 'socket'

module Logistics
  class KeyMaster
    include ManagedSSH
  
    attr_accessor :hosts, :user
    def initialize(hosts, user = "root")
      self.hosts = hosts
      self.user = user
    end
  
    def upload_public_keys(default_password = 'secrets')
      hosts.each do |host|
        if key_based_login_successful?(host)
          puts "    * key already present and effective on #{host}"
        else
          upload_key(host, default_password)
        end
      end
    end
  
    def key_based_login_successful?(host)
      begin
        connect_to(host)
      rescue Net::SSH::AuthenticationFailed
        return nil
      end
      connections[host]
    end
  
    def upload_key(host, default_password)
      begin
        ssh = Net::SSH.start(host, user, :password => default_password)
      rescue Net::SSH::Exception => e
        puts "Can't connect to #{host}: #{e}!"
        return false
      end
    
      keyfile = File.join(ENV['HOME'],'.ssh','id_rsa.pub')
      if File.exist?(keyfile)
        output = ssh.exec!("cat ~/#{user}\\@#{Socket.gethostname}_id_rsa.pub")
        if output =~ /No such file/
          user_home_path = ssh.exec!("echo ~").strip
          ssh.sftp.upload!(keyfile, "#{user_home_path}/#{user}@#{Socket.gethostname}_id_rsa.pub")
          ssh.exec!("mkdir ~/.ssh")
          puts "  * executing cat ~/#{user}\\@#{Socket.gethostname}_id_rsa.pub >> ~/.ssh/authorized_keys on #{host}"
          output = ssh.exec!("cat ~/#{user}\\@#{Socket.gethostname}_id_rsa.pub >> ~/.ssh/authorized_keys; cat ~/.ssh/authorized_keys")
          puts output
        else
          puts "  * ~/#{user}\\@#{Socket.gethostname}_id_rsa.pub already exists on server\""
        end
      else
        puts "  * you have no rsa public key at #{keyfile}!"
      end
      ssh.close
    end
  end
end