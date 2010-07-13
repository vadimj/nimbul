class ServiceType < BaseModel
  has_many :service_providers, :include => :server
  
  validates_presence_of :name, :fqdn
  validates_uniqueness_of :name
  
  def providers
    service_providers
  end
end
