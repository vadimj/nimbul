
class BlockDeviceMapping < BaseModel
	belongs_to :launch_configuration
    
    validates_presence_of :virtual_name, :device_name

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
    
end
