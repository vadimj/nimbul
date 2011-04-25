class ServerUserAccess < BaseModel
    belongs_to :server
    belongs_to :user

    validates_presence_of :server_id, :user_id, :server_user

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
