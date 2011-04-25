class ServerProfileRevisionParameter < BaseModel
    belongs_to :server_profile_revision
	has_many :task_parameters, :as => :value_provider
	
    validates_presence_of :name, :value
    validates_format_of   :name, :with => /\A\w[\w\.\-_]+\z/,
        :message => "use only letters, numbers, and .-_ please."

	attr_accessor :should_destroy

	before_destroy :abandon_task_parameters
    
	def abandon_task_parameters
		self.task_parameters.each do |tp|
			tp.update_attributes({
				:value => self.value,
				:value_provider_type => nil,
				:value_provider_id => nil,
			})
		end
	end

    def should_destroy?
        should_destroy.to_i == 1
    end
end
