class CloudAddress < CloudResource
	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    def self.default_mount_type
		'AssignAddressMountType'
    end

	def available?
		state == 'available'
	end

    def allocate!
        begin
            Ec2Adapter.allocate_address(self)
            self.save
        rescue Exception => e
			msg = "Failed to allocate address '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
            self.status_message = msg
            self.destroy
            return false
        end
        return true
	end

    def release!
		# make sure it's not being used
		unless self.server_resources.empty?
			self.errors.add(:state, "is being used by some servers")
			return false
		end
		unless self.instance_resources.empty?
			self.errors.add(:state, "is being used by some instances")
			return false
		end
		
		# release
        begin
            self.destroy
            Ec2Adapter.release_address(self)
        rescue Exception => e
			msg = "Failed to release address '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
            return false
        end
        
        return true
    end
    
    def self.create_from(address)
		a = build({
			:provider_account_id => address.provider_account_id,
			:cloud_id => address.public_id,
			:name => address.name,
			:state => address.state,
			:is_enabled => address.is_enabled,
			:cloud_instance_id => address.instance_id,			
		})
		a.save
    end
end
