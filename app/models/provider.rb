class Provider < BaseModel
    behavior :service
    
    service_parent_relationship :none
    service_child_relationship  :provider_accounts
    
    validates_presence_of :name, :long_name, :adapter_class
    validates_uniqueness_of :name, :long_name
#    validates_uri_existence_of :endpoint_url, :with =>
#        /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
#        :on => :create
    has_many :regions, :dependent => :destroy
    has_many :provider_accounts, :dependent => :nullify
    has_many :operating_systems, :dependent => :destroy
    has_many :instance_kind_categories, :dependent => :destroy, :include => :instance_kinds, :order => :position
end
