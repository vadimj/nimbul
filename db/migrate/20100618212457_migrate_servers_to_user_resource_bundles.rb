class MigrateServersToUserResourceBundles < ActiveRecord::Migration
    def self.up
		puts "Importing Addresses into CloudAddresses"
		Address.all.each do |a|; CloudAddress.create_from(a); end
		puts "Importing Volumes into CloudVolumes"
		Volume.all.each do |v|; CloudVolume.create_from(v); end
		puts "Importing Snapshots into CloudSnapshots"
		Snapshot.all.each do |s|; CloudSnapshot.create_from(s); end
		puts "Migrating Servers"
        Cluster.reset_column_information
        Cluster.find(:all, :include => [ :provider_account, :servers, :cloud_resources ], :order => 'name' ).each do |cluster|
            puts "Processing cluster #{cluster.name} [#{cluster.id}]"
            cluster.servers.sort{ |a,b| a.name <=> b.name }.each do |server|
              puts "\tProcessing server #{server.name} [#{server.id}]"
                instance_id = nil
                instance_id = server.instances.last.id unless server.instances.empty?

                address = nil
                unless server.public_ip.blank?
                  begin
                      address = CloudResource.find_by_provider_account_id_and_cloud_id(cluster.provider_account_id, server.public_ip)
                      puts "\t\tFound #{address.cloud_id} [#{address.id}]"
                  rescue Exception => e
                      puts "\t\tCouldn't find cloud resource for #{server.public_ip}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
                  end
                end

                volume = nil
                volume_class = server.volume_class
                unless server.volume_id.blank?
                  begin
                      volume = CloudResource.find_by_provider_account_id_and_cloud_id(cluster.provider_account_id, server.volume_id)
                      puts "\t\tFound #{volume.cloud_id} [#{volume.id}]"
                  rescue Exception => e
                      puts "\t\tCouldn't find cloud resource for #{server.volume_id}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
                  end
                end
            
                next if address.nil? and volume.nil?
            
                if server.resource_bundles.empty?
                    rb = server.resource_bundles.build({
  			            :instance_id => instance_id,
  			            :zone_id => (server.zone_id.blank? ? nil : server.zone_id),
  			            :is_default => true,
			        })
    			    rb.save
                else
                    rb = server.resource_bundles.first
                end
			
			    unless address.nil?
                    sr = rb.server_resources.detect{|r| r.cloud_resource_id == address.id}
                    if sr.nil?
    			        sr = rb.server_resources.build({
    				        :cloud_resource_id => address.id,
    					    :mount_type => address.class_type.constantize.default_mount_type,
    					    :force_allocation => server.force_public_ip_allocation,
    				    })
                    end
				    sr.class_type = address.class_type.constantize.server_resource_type
				    sr.save
				    cluster.cloud_resources << address unless cluster.cloud_resources.include?(address)
			    end
			
			    mount_type_map = {}
			    mount_type_map['Volume'] = 'MountVolumeMountType'
			    mount_type_map['AnotherServer'] = 'RestoreLatestSnapshotMountType'
			    mount_type_map['Snapshot'] = 'RestoreSnapshotMountType'
		        unless volume.nil?
                    mount_type = mount_type_map[volume_class] || volume.class_type.classify.default_mount_type
                    sr = rb.server_resources.detect{|r| r.cloud_resource_id == volume.id}
                    if sr.nil?
    			        sr = rb.server_resources.build({
    				        :cloud_resource_id => volume.id,
    					    :mount_type => mount_type,
    					    :force_allocation => server.force_volume_id_allocation,
    					    :mount_point => server.device,
    				    })
    			    end
				    sr.class_type = volume.class_type.constantize.server_resource_type
				    sr.save
				    cluster.cloud_resources << volume unless cluster.cloud_resources.include?(volume)
		        end
            end
        end
    end
    
    def self.down
        raise ActiveRecord::IrreversibleMigration, "Can't reliably convert new Resource Bundles to old Servers"
    end
end
