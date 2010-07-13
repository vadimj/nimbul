class InstanceVolume < InstanceResource
    validates_presence_of :mount_point
    validates_uniqueness_of :mount_point, :scope => :instance_id, :allow_blank => true, :message => 'already used by another volume'
end
