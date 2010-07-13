class MountVolumeMountType < ServerVolumeMountType
    def self.cloud_resource_types
        ['CloudVolume']
    end
    
    def self.care_about_zone?
        true
    end

    def self.allow_multiple_allocations?
        false
    end
end
