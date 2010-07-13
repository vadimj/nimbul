
class InstanceCloudResourceAllocation < BaseModel
    belongs_to :instance
    belongs_to :cloud_resource

    validates_presence_of :instance_id, :cloud_resource_id

	attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
