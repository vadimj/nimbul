class RestoreSnapshotMountType < ServerVolumeMountType
    def self.allocate!(cloud_resource, zone)
        # check the type
        self.support_cloud_resource?(cloud_resource) do |result, msg|
            unless result
                yield nil, msg
                return
            end
        end
        
        # allocate
        prefix = self.name+" from #{cloud_resource.name} "+Time.now.to_s(:volume_snapshot_name)
		begin
			volume = cloud_resource.restore!(zone, prefix)
		rescue
    		yield nil, "Failed to restore #{cloud_resource.short_type} '#{cloud_resource.name}': #{$!}"
		end
		
		# return
		yield volume, "Found #{cloud_resource.short_type} '#{cloud_resource.name}', restored to #{volume.name}"
    end

    def self.cloud_resource_types
        ['CloudSnapshot', 'CloudVolume']
    end

    def self.care_about_zone?
        false
    end

    def self.allow_multiple_allocations?
        true
    end
end
