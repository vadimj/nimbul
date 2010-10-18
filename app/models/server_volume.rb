class ServerVolume < ServerResource
    validates_presence_of :mount_type
    validates_presence_of :mount_point
    validates_uniqueness_of :mount_point, :scope => :resource_bundle_id, :allow_blank => true, :message => 'already used by another resource in this Launch Configuration'
    validates_format_of :mount_point, :with => %r{/dev/sd[a-z]}, :message => 'device attachment point must match /dev/sd[a-z] and not already be in use'
#    this wouldn't work for restoring snapshots - disabling until there is a better solution
#    validates_uniqueness_of :cloud_resource_id, :scope => [ :resource_bundle_id, :type ], :message => 'already mounting in this Launch Configuration'
end
