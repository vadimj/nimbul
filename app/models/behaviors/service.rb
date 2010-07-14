module Behaviors::Service
  module ClassBehaviors
    # behavior_class_init is automatically run after the class is extended
    # and then removed from further use (via undef_method)
    def behavior_class_init
      has_many :service_overrides, :as => :target
      has_many :service_providers, :through => :service_overrides, :source => :service_provider
      
      class_eval(<<-EOS, __FILE__, __LINE__)
        @@service_relationships = {:parent => nil, :children => nil}
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
      rel = (service_relationships[:parent] == :none ? nil : service_relationships[:parent])
      send(rel, *args) unless rel.nil?
    end

    def service_children *args
      rel = (service_relationships[:children] == :none ? nil : service_relationships[:children])
      send(rel, *args) unless rel.nil?
    end
    
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
      while_walking_service_provider_lineage do |ancestor|
        provider = ancestor.service_override(type).try(:provider)
        break unless provider.nil?
      end
      
      provider
    end

    def service_progenitor
      progenitor = nil
      while_walking_service_provider_lineage do |ancestor|
        progenitor = ancestor
      end
      progenitor
    end
    
    def service_dns_records=(v); end
    def service_dns_records
      services.values.collect { |s| s.hostline rescue nil }.select{ |line| !line.nil? }.join "\n"
    end
    
    
    def services
      ServiceType.all.inject({}) do |services,stype|
        services[stype.name] = service stype
        services
      end
    end
    
    def service_override name
      stype = name.instance_of?(ServiceType) ? name: ServiceType[name.to_s]
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
