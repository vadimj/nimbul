# Provides support for including behaviors (mixins) in a consistent manner
# including keeping track of inherited behaviors through ancestors (see: BaseModel)

module Behaviors

  def self.included klass
    klass.class_eval(<<-EOS, __FILE__, __LINE__)
      # provides support for inheritable behaviors, both class and instance based
      class_inheritable_accessor :class_behaviors, :instance_behaviors
      write_inheritable_attribute :class_behaviors, [].dup
      write_inheritable_attribute :instance_behaviors, [].dup
      
      def self.behavior *behaviors
        behaviors = behaviors.delete_if {|b| b.is_a? Hash }
        options   = (behaviors.last if behaviors.last.is_a? Hash) || {}
        Behaviors.include(self, behaviors, options)
      end
      
      class << self
        alias_method :behaviors, :behavior

        unless Rails.configuration.cache_classes
          ActionController::Dispatcher.before_dispatch do
            write_inheritable_attribute :class_behaviors, [].dup
            write_inheritable_attribute :instance_behaviors, [].dup
            @@cached = {}
          end
        end
        
        def kind_of? klass
          unless klass.to_s[/Behaviors::([^:]+)/,1].nil?
            return (class_behaviors|instance_behaviors).include? $1.to_sym
          end
          super klass 
        end
      end
    EOS
  end
  
  class << self
    @@behaviors = nil
    @@loaded_behaviors = false
    
    def include(klass, what, opts = {})
      load_behaviors

      what = [what].flatten.include?(:all) ? @@behaviors : [what].flatten.collect { |b| b.to_s.camelize.to_sym }
      
      exceptions = opts.delete(:except) || opts.delete(:exceptions) || []
      exceptions = [exceptions].flatten.select { |e| e.camelize.to_sym }

      modules = @@behaviors.select do |b|
        what.include?(b) && !exceptions.include?(b)
      end.inject({}) do |hash,behavior|
        hash[behavior] = behavior_constants behavior
        hash
      end
      
      modules.each_key do |behavior|
        setup_class_behavior klass, behavior, modules[behavior][:class]
        setup_instance_behavior klass, behavior, modules[behavior][:instance]
      end
    end
    
    private
    
    def setup_class_behavior klass, behavior, b_module
      unless b_module.nil? or klass.class_behaviors.include? behavior
        klass.extend b_module
        unless not klass.respond_to? :behavior_class_init
          klass.behavior_class_init
          class << klass
            undef_method :behavior_class_init
          end
        end
        klass.class_behaviors << behavior
      end
    end
    
    def setup_instance_behavior klass, behavior, b_module
      unless b_module.nil? or klass.instance_behaviors.include? behavior
        klass.class_eval(<<-EOS, __FILE__, __LINE__)
          include #{b_module}
          def after_initialize
            behavior_instance_init unless not self.respond_to? :behavior_instance_init
            super unless not respond_to? :super
          end
        EOS
        klass.instance_behaviors << behavior
      end
    end
  
    def load_behaviors
      unless @@loaded_behaviors
        file = File.expand_path(__FILE__)[/(app\/models.*)/,1]
        path = File.join(RAILS_ROOT, File.dirname(file), File.basename(file, '.rb'))
        begin
          @@behaviors ||= Dir[File.join(path, '*.rb')].collect do |behavior|
            result = require behavior
            File.basename(behavior,'.rb').camelize.to_sym
          end.compact
        rescue Exception => e
          puts "Exception caught: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
        end
        
        @@loaded_behaviors = true
      end
    end
    
    def behavior_constants behavior
      (@@cached||={})[behavior] = { # lazy "load" - and only do it once
        :class    => begin
          Behaviors.const_get(behavior).const_get('ClassBehaviors')
        rescue NameError
          nil
        end,
        
        :instance => begin
          Behaviors.const_get(behavior).const_get('InstanceBehaviors')
        rescue NameError
          nil
        end
      }
    end
  end
end
