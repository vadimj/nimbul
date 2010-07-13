class ReservedInstance < BaseModel
    belongs_to :provider_account
    belongs_to :zone
end
