require 'rubygems'
require 'chronic'

class ServerTask < BaseModel
    belongs_to :server
    has_many :server_task_parameters, :dependent => :destroy
    has_many :operations, :dependent => :nullify

	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    validates_presence_of :name
    validates_associated :server_task_parameters

    validate :repeatable_must_have_run_every_value

    def repeatable_must_have_run_every_value
        errors.add_to_base("Must specify how often to Repeat") if is_repeatable? and (run_every_value.blank? or run_every_value <=0)
    end

    before_save  :set_run_at, :set_run_every
    after_update :save_server_task_parameters

    attr_accessor :should_destroy, :run_every, :state_text, :scheduler_tag, :new_operations
    
	include TrackChanges # must follow any before filters

    def run_every
        return nil unless is_repeatable?
        "#{self.run_every_value}#{self.run_every_units[0,1]}"
    end

    def should_destroy?
        should_destroy.to_i == 1
    end

    def set_run_at
        if self.run_at.blank? and self.is_repeatable?
            self.run_at = Chronic.parse("#{self.run_in_value} #{self.run_in_units} from now")
        end
    end

    def set_run_every
        unless is_repeatable?
            self.run_every_value = nil
            self.run_every_units = nil
        end
    end

    def save_server_task_parameters
        server_task_parameters.each do |i|
            if i.should_destroy?
                i.destroy
            else
                i.save(false)
            end
        end
    end

    def server_task_parameter_attributes=(server_task_parameter_attributes)
        server_task_parameter_attributes.each do |attributes|
            if attributes[:id].blank?
                server_task_parameters.build(attributes)
            else
                server_task_parameter = server_task_parameters.detect { |c| c.id == attributes[:id].to_i }
                server_task_parameter.attributes = attributes
            end
        end
    end

    def parameter_value(name)
        parameter = server_task_parameters.detect{|p| p.name == name}
        if parameter.nil?
            return nil
        else
            return parameter.value
        end
    end

    def initialize_parameters
        []
    end

    def options(name)
        []
    end

    def scheduler_tag
        "server_task_#{self.id}"
    end
    
    def call(job)
        run!
    end

	def get_operation
		op = Operation.factory(self.operation)
		op.server_task_id = self.id
		return op
	end

    def self.find_all_by_parent(parent, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
		send("find_all_by_#{ parent.class.to_s.underscore }", parent, search, page, extra_joins, extra_conditions, sort, filter)
	end

    def self.find_all_by_server(server, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'server_id = ?', (server.is_a?(Server) ? server.id : server) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    self.search(search, page, joins, conditions, sort, filter)
    end
  
    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name)
    end

    def self.search_fields
        %w(name)
    end
    
	def self.filter_fields
		%w(status owner_id)
	end

    def run!
        begin
            server.instances.each do |instance|
                next if not instance.running?
                operation = get_operation
                instance.operations << operation
                # store to return to the ui
                self.new_operations = [] if self.new_operations.nil?
                self.new_operations << operation
            end
        rescue
            self.state_text = "Task failed: #{$!}"
            return false
        end
        return true
    end
end
