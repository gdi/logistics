module Logistics
  module ServiceKit
    class Supervise < Kit
    
      def before_install
        if multi_instanced?
          instances.to_i.times do |instance_id|
            instance_id += 1 # not zero indexed, plz
            ssh.exec! "mkdir -p /service/#{directory_name(instance_id)}"
          end
        else
          ssh.exec! "mkdir -p /service/#{directory_name}"
        end
      end
    
      def after_install
        if multi_instanced?
          instances.to_i.times do |instance_id|
            instance_id += 1 # not zero indexed, plz
            ssh.exec! "chmod 755 /service/#{directory_name(instance_id)}/run"
          end
        else
          ssh.exec! "chmod 755 /service/#{directory_name}/run"
        end
      end
    
      def path_to_control_script id = nil
        "/service/#{directory_name(id)}/run"
      end
    
      def directory_name id = nil
        id ? "#{package_name}_#{id}" : package_name
      end
    
      def multi_instanced?
        service_data["instances"]
      end
    
      def instances
        service_data["instances"].to_i
      end
    
      def install
        if multi_instanced?
          instances.to_i.times do |instance_id|
            instance_id += 1 # not zero indexed, plz
            rendered = render_control_script({
              "instance" => instance_id,
              "port" => service_data["start_at"] + instance_id
            })
            ssh.sftp.upload!  StringIO.new(rendered),
                              path_to_control_script(instance_id)
          end
        else
          rendered = render_control_script
          ssh.sftp.upload! StringIO.new(rendered), path_to_control_script
        end
      end
    
    end
  end
end