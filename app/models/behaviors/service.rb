module Behaviors::Service
  module ClassBehaviors
    # behavior_class_init is automatically run after the class is extended
    # and then removed from further use (via undef_method)
    def behavior_class_init
      has_many :service_overrides, :as => :target
      has_many :service_providers, :through => :service_overrides, :source => :service_provider
      
      class_eval(<<-EOS, __FILE__, __LINE__)
        @@service_relationships = {:parent => :none, :children => :none}
      EOS

      cattr_accessor :service_relationships
    end
    
    def service_parent_relationship association = :none
      service_relationships[:parent] = association.to_s.to_sym
    end

    def service_child_relationship association = :none
      service_relationships[:children] = association.to_s.to_sym
    end
  end

  module InstanceBehaviors
    def behavior_instance_init
      @none = nil
    end
    
    def service_parent *args
      unless self.class.service_relationships[:parent] == :none
        send self.class.service_relationships[:parent], *args
      end
    end

    def service_children *args
      unless self.class.service_relationships[:children] == :none
        send self.class.service_relationships[:children], *args
      end
    end
    
    alias :service_ancestor :service_parent
    alias :service_descendents :service_children
    
    def has_service_children?() !!service_children rescue false; end
    def has_service_parent?() !!service_parent rescue false; end
    
    alias :is_service_parent? :has_service_children?
    alias :is_service_child?  :has_service_parent?

    def can_override_service? type
      overridable = true
      while_walking_service_provider_lineage do |ancestor|
        parent_service = ancestor.service_override(type)
        overridable &= parent_service.overridable? unless parent_service.nil?
      end
      overridable
    end

    def service type
      provider = nil
      service_ancestors.each do |ancestor|
        override = ServiceOverride.first(
          :select => %Q(
            service_overrides.id,
            service_overrides.overridable,
            service_overrides.service_provider_id,
            st.name
          ),
          :joins => [
            'INNER JOIN service_providers AS sp ON service_overrides.service_provider_id = sp.id',
            'INNER JOIN service_types AS st on sp.service_type_id = st.id'
          ],
          :conditions => {
            :service_overrides => {
              :target_type => ancestor.class.name,
              :target_id   => ancestor[:id]
            },
            :st => { :name => type.is_a?(ServiceType) ? type.name.to_s : type.to_s }
          }
        )

        unless override.nil?
          provider = override[:service_provider_id]
          break unless override.overridable?
        end
      end

      provider.nil? ? nil : ServiceProvider.find(provider)
    end

    def service_progenitor
      progenitor = nil
      while_walking_service_provider_lineage do |ancestor|
        progenitor = ancestor
      end
      progenitor
    end
    
    def service_ancestors
      if @ancestors.empty?
        @ancestors ||= (service_parent.service_ancestors rescue []) + [self]
      end
      @ancestors
    end
    
    def service_dns_records=(v); end
    def service_dns_records
      services.values.select{|v| !v.nil?}.collect { |s| s.hostline }.join "\n"
    end
    
    
    def services
      @services ||= ServiceType.all.inject({}) do |services,stype|
        services[stype.name] = service stype
        services
      end
    end
    
    def service_override name
      stype = name.instance_of?(ServiceType) ? name: ServiceType.find_by_name(name.to_s)
      return nil unless not stype.nil?
      service_overrides(:include => :service_provider).by_type(stype.name).first rescue nil
    end

    def while_walking_service_children level = 0, &block
      obj = self
      obj.service_children && obj.service_children.each do |child|
        block.call(child, level)
        child.while_walking_service_children(level + 1, &block)
      end
    end
    
    def while_walking_service_provider_lineage 
      obj = self
      begin
        yield obj
        obj = obj.service_parent
      end until obj.nil?
    end
    
    def service_lineage_text
      ancestors = []
      while_walking_service_provider_lineage do |ancestor|
        ancestors << ancestor unless ancestor.service_parent.nil?
      end
      ancestors.reverse.collect{|a| a.name }.join(" - ")
    end
  end
end
