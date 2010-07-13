
class ServerProfileRevisionParameter < BaseModel
    belongs_to :server_profile_revision
    
    validates_presence_of :name, :value
    validates_format_of   :name, :with => /\A\w[\w\.\-_]+\z/,
        :message => "use only letters, numbers, and .-_ please."

	attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
