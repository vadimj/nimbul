class StatRecord < BaseModel
    belongs_to :provider_account
    has_many :instance_allocation_records, :include => :zone
end
