
class ServiceOverride < BaseModel
  belongs_to :service_provider, :include => [ :service_type, :server ]
  belongs_to :target, :polymorphic => true
 
  def name
    provider.name
  end
  
  def provider 
    service_provider
  end
  
  def type
    provider.service_type 
  end
  
  def validate
    errors.add_on_empty %w( service_provider_id target_id target_type)
    stype  = service_provider.service_type
    target = target_type.constantize.find(target_id)
    unless target.service_parent.nil? or target.service_parent.can_override_service? stype
      errors.add "Can't override provider of service '#{stype.name}' " +
                 "due to override restriction set on parent #{target.service_parent.class.name.titleize} " +
                 "'#{target.service_parent.try(:name)}'. New service override "
    end
    
    overrides = ServiceOverride.find_all_by_target_id_and_target_type(target_id, target_type)
    if overrides.any? { |so| so.type == stype && so != self }
      errors.add "Target already contains this service - new service override "
    end
  end
  
  named_scope :by_type, lambda {  |type|
    {
      :include => { :service_provider => :service_type },
      :conditions => [
        'service_types.id = ?', (type.is_a?(ServiceType) ? type.id : ServiceType.find_by_name(type.to_s).id)
      ]
    }
  }
end
