
class InstanceListReader < BaseModel
    belongs_to :provider_account

    validates_presence_of :name, :s3_user_id

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
