class AssignAddressMountType < ServerResourceMountType
    def self.cloud_resource_types
        ['CloudAddress']
    end

    def self.care_about_zone?
        false
    end
    
    def self.allow_multiple_allocations?
        false
    end

    def self.can_mount_resource?(cloud_resource)
        return cloud_resource_types.include?(cloud_resource.class_type)
    end
end
