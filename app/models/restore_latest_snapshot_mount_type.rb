class RestoreLatestSnapshotMountType < RestoreSnapshotMountType
    def self.allocate!(cloud_resource, zone)
        # check the type
        self.support_cloud_resource?(cloud_resource) do |result, msg|
            unless result
                yield nil, msg
                return
            end
        end

        # get snapshots
        snapshots = CloudSnapshot.find_all_by_provider_account_id_and_parent_cloud_id(cloud_resource.provider_account_id, cloud_resource.cloud_id)
        unless snapshots.size > 0
            yield nil, "#{cloud_resource.short_type} '#{cloud_resource.name}', doesn't have any snapshots."
            return
        end
        
        # find the latest snapshot
        snapshots.sort!{ |a, b| b.start_time <=> a.start_time }
        snapshot = snapshots[0]
        super(snapshot, zone)
    end
    
    def self.cloud_resource_types
        ['CloudVolume']
    end

    def self.care_about_zone?
        false
    end

    def self.allow_multiple_allocations?
        true
    end
end
