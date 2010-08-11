class TaskParameter < BaseModel
    belongs_to :task
    belongs_to :value_provider, :polymorphic => true
    
    validates_presence_of :name
    validates_format_of   :name, :with => /\A\w[\w\.\-_]+\z/,
        :message => "use only letters, numbers, and .-_ please."
    validates_presence_of :custom_value, :if => :custom_value_and_value_provider_are_blank?,
        :message => 'please choose existing parameter or specify a value manually'
        
    attr_accessor :value, :is_protected
        
    def custom_value_and_value_provider_are_blank?
        self.custom_value.blank? and self.value_provider.nil?
    end
    
    # value and is_protected are coming from value_provider (if defined) or the parameter itself
    def value
        return self.value_provider.value if self.value_provider and self.value_provider.respond_to?(:value)
        return self.custom_value
    end

    def is_protected
        return self.value_provider.is_protected if self.value_provider and self.value_provider.respond_to?(:is_protected)
        return false
    end
end
