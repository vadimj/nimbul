class InstanceKindCategory < ActiveRecord::Base
  belongs_to :provider
  has_many :instance_kinds
  
  validates_presence_of :provider_id, :name
  validates_uniqueness_of :name, :scope => :provider_id
end
