class Zone < BaseModel
    belongs_to :provider_account
    belongs_to :region
    
    has_and_belongs_to_many :auto_scaling_groups
    
    has_many :instances, :dependent => :nullify
    has_many :instance_allocation_records, :dependent => :nullify
    has_many :resource_bundles, :dependent => :nullify
    has_many :cloud_resources, :dependent => :nullify
    has_many :volumes, :class_name => 'CloudVolume', :dependent => :nullify
    has_many :snapshots, :class_name => 'CloudSnapshot', :dependent => :nullify
    has_many :reserved_instances, :dependent => :nullify
    
    validates_uniqueness_of :name, :scope => [ :provider_account_id ], :message => 'there is already a zone with this name under this Account'

    def has_resources?
        !instances.empty? or
            !instance_allocation_records.empty? or
            !resource_bundles.empty? or
            !cloud_resources.empty?
    end

    def to_s
        name
    end
end