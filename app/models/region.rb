
class Region < BaseModel
    belongs_to :provider
    has_many :zones
    validates_presence_of :name, :endpoint_url
    validates_uniqueness_of :name, :scope => :provider_id

    serialize :meta_data, Hash
end
