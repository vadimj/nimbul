class OperatingSystem < ActiveRecord::Base
    belongs_to :provider
    
    validates_presence_of :provider_id, :name
    validates_uniqueness_of :name, :scope => :provider_id
end
