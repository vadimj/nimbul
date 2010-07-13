
class ServerProfileUserAccess < BaseModel
    belongs_to :server_profile
    belongs_to :user
    
    validates_presence_of :server_profile_id, :user_id, :role

	attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
