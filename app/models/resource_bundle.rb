
class ResourceBundle < BaseModel
    belongs_to :server
    belongs_to :instance
    belongs_to :zone
    
	has_many :server_resources, :dependent => :destroy
	has_many :addresses, :class_name => 'ServerAddress', :dependent => :destroy
	has_many :volumes, :class_name => 'ServerVolume', :dependent => :destroy
	
	validates_associated :addresses, :volumes
	after_save :save_addresses, :save_volumes

	def class_type=(value) self[:type] = value; end
	def class_type() return self[:type]; end

	def mountee_class_name
		'launch configuration'
	end

	def can_use_more_of?(server_resource_type)
		return true if server_resource_type == 'ServerVolume'
		return true if (server_resource_type == 'ServerAddress' and self.addresses.empty?)
		return false
	end
	
    def save_addresses
        addresses.each do |i|
            if i.should_destroy?
                i.destroy
            else
                i.save(false)
            end
        end
    end

    def address_attributes=(address_attributes)
        address_attributes.each do |attributes|
            if attributes[:id].blank?
                addresses.build(attributes) unless attributes[:cloud_resource_id].blank?
            else
                address = server_resources.detect { |c| c.id == attributes[:id].to_i }
                address.attributes = attributes
            end
        end
    end

    def save_volumes
        volumes.each do |i|
            if i.should_destroy?
                i.destroy
            else
                i.save(false)
            end
        end
    end

    def volume_attributes=(volume_attributes)
        volume_attributes.each do |attributes|
            if attributes[:id].blank?
				volumes.build(attributes) unless attributes[:cloud_resource_id].blank?
            else
                volume = server_resources.detect { |c| c.id == attributes[:id].to_i }
                volume.attributes = attributes
            end
        end
    end

	def release!
		self.update_attribute(:instance_id, nil)
	end

	def allocate!(instance)
		msg_prefix = "Launch Configuration (resource bundle) [#{self.id}]"
		# allocate all resources associated with this configuration
		self.server_resources.each do |sr|
			cr = nil
			cloud_resource_id = sr.cloud_resource.id
			state = 'pending'
			state_description = 'pending'
			mount_type = sr.mount_type
					
			# allocate the resource
			sr.mount_type.constantize.allocate!(sr.cloud_resource, instance.zone) do |cr, msg|
				if cr.nil?
					state = 'failed'
					state_description = msg
				else
					cloud_resource_id = cr.id
					mount_type = cr.class.default_mount_type
				end
			end
			
			# save the new instance resource
			ir = instance.instance_resources.build({
			    :class_type => sr.class.instance_resource_type,
			    :cloud_resource_id => cloud_resource_id,
			    :state => state,
			    :state_description => state_description,
			    :force_allocation => sr.force_allocation,
			    :params => sr.params,
			    :mount_point => sr.mount_point,
			    :mount_type => mount_type,
			})
			ir.save
			
			# if allocation of one of the resources failed - stop allocaon
			if cr.nil?
				msg = "#{msg_prefix} allocate!: failed to use Mounter '#{sr.mount_type}' for #{sr.cloud_resource.cloud_id}: #{state_description}"
				raise msg
			end
		end
		
		self.update_attribute(:instance_id, instance.id)
		instance.update_attribute( :pending_launch_configuration_id, nil )
		
		return true
	end

	def start!(count=1, options={})
		server = self.server
		options.merge!({ :resource_bundle_id => self.id })
		instances = []
		
		begin
			instances = server.start!(count, options)
			update_attribute(:instance_id, instances.last.id) unless instances.last.nil?
			unless server.errors.empty?
				server.errors.each do |attr, msg|
					self.errors.add(:server_id, "#{attr}, #{msg}")
				end
			end
		rescue Exception => e
			msg = "Failed to start server '#{server.name}' [#{server.id}] using launch configuration [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
		end
		
		return instances
	end
end
