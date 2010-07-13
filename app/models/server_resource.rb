
class ServerResource < BaseModel
    belongs_to :resource_bundle
    belongs_to :cloud_resource, :counter_cache => true

    serialize :params, Hash
    attr_accessor :should_destroy, :status_message, :destroyed, :cloud_resource_type

    validates_presence_of :cloud_resource_id, :mount_type
    before_save :validate_cloud_resource
    
    def should_destroy?
        should_destroy.to_i == 1
    end

    def validate_cloud_resource
        unless self.cloud_resource_id.nil?
            cr = CloudResource.find(self.cloud_resource_id)
            if cr.nil?
                self.errors.add(:cloud_resource_id, "couldn't find cloud resource [#{self.cloud_resource_id}]")
                raise ActiveRecord::Rollback
#            elsif !self.can_use_cloud_resource?(cr)
#                self.errors.add(:cloud_resource_id, "can't use cloud resource '#{cr.name}' [#{cr.id}]")
#                raise ActiveRecord::Rollback
            end
        end
    end

	def class_type=(value) self[:type] = value; end
	def class_type() return self[:type]; end

	def self.factory(klass_type, *params)
		class_name = klass_type.nil? ? 'ServerResource' : klass_type

		_class = class_name.constantize rescue nil
		if not _class.nil? and _class.name == class_name
			return _class.new(*params)
		end

		# fallback to base
		return ServerResource.new(params)
	end

    def self.instance_resource_type(server_resource_type=nil)
		server_resource_type ||= self.to_s
		server_resource_type.gsub('Server', 'Instance')
    end
end
