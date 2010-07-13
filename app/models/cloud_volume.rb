class CloudVolume < CloudResource
	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    def self.default_mount_type
		'MountVolumeMountType'
    end

	def available?
		state == 'available'
	end
	
    def allocate!
        if self.save
            begin
                size_or_snapshot = self.size.blank? ? self.parent_cloud_id : self.size
                res = Ec2Adapter.create_volume(self, size_or_snapshot, self.zone)
                self.update_attributes(res)
                return true
            rescue Exception => e
				msg = "Failed to allocate volume '#{self.name}' [#{self.id}]: #{e.message}"
				Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
				self.errors.add(:state, "#{msg}")
                self.destroy
                return false
            end
        else
            return false
        end
	end

    def snapshot!(suffix = Time.now.to_s(:volume_snapshot_name))
		snapshot_name = suffix.blank? ? self.name : self.name+' '+suffix
		snapshot = self.provider_account.snapshots.build({
			:name => snapshot_name,
		})
        # expose this snapshot to all the clusters the original volume is exposed to
        snapshot.clusters = (self.clusters) unless self.clusters.empty?
		if snapshot.save
            begin
            	res = Ec2Adapter.create_snapshot(self)
                snapshot.update_attributes(res)
            rescue Exception => e
				msg = "Failed to snapshot volume '#{self.name}' [#{self.id}]: #{e.message}"
				Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
				snapshot.destroy
                self.errors.add(:state, "#{msg}")
                return nil
            end
        end
        return snapshot
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
            Ec2Adapter.delete_volume(self)
            self.update_attribute(:state, 'deleting')
		rescue Exception => e
			msg = "Failed to delete volume '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
            return false
        end
        
        return true
    end
end
