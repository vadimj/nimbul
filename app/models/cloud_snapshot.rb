class CloudSnapshot < CloudResource
	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    def self.default_mount_type
		'MountVolumeMountType'
    end

    def restore!(zone = nil, prefix = '')
		volume_name = prefix.blank? ? self.name : prefix+' '+self.name 
		volume = self.provider_account.volumes.build({
			:name => volume_name,
		})
        # expose this volume to all the clusters the original snapshot is exposed to
        volume.clusters = (self.clusters) unless self.clusters.empty?
		if volume.save
            begin
            	res = Ec2Adapter.create_volume(volume, self.cloud_id, zone)
                volume.update_attributes(res)
            rescue Exception => e
				msg = "Failed to restore snapshot '#{self.name}' [#{self.id}]: #{e.message}"
				Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
				volume.destroy
                self.errors.add(:state, "#{msg}")
                return nil
            end
        end
        return volume
	end

    def delete!
		# make sure it's not being used
		unless self.server_resources.empty?
			self.errors.add(:state, "is being used by some servers")
			return false
		end
		unless self.instance_resources.empty?
			self.errors.add(:state, "is being used by some instances")
			return false
		end
		
		# delete
        begin
            Ec2Adapter.delete_snapshot(self)
            self.update_attribute(:state, 'deleting')
		rescue Exception => e
			msg = "Failed to delete snapshot '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
            return false
        end
        
        return true
    end

    def self.create_from(snapshot)
		a = new({
			:provider_account_id => snapshot.provider_account_id,
			:cloud_id => snapshot.snapshot_id,
			:name => snapshot.name,
			:state => snapshot.status,
			:parent_cloud_id => snapshot.volume_id,
			:owner_id => snapshot.owner_id,
			:description => snapshot.description,
			:start_time => snapshot.start_time,
			:progress => snapshot.progress,
			:is_enabled => snapshot.is_enabled,
			:cloud_instance_id => snapshot.instance_id,			
		})
		a.save
    end
end
