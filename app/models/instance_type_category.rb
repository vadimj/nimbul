class InstanceTypeCategory < ActiveRecord::Base
    belongs_to :provider
    has_many :instance_kinds
end
