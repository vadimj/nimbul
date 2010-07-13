require 'aasm'

class Operation < BaseModel
	class InvalidOperationTypeError < TypeError; end

	include AASM
	behaviors :operating, :event_publisher
  
	serialize :args, Hash

	belongs_to :instance
	belongs_to :server_task

	has_many :messages
	has_many :operation_logs, :dependent => :destroy

	aasm_column :state
	aasm_initial_state :proceed

	aasm_state :waiting
	aasm_state :proceed,   :enter => :initiate_proceed
	aasm_state :timedout,  :enter => :initiate_timeout
	aasm_state :failed,    :enter => :initiate_failure
	aasm_state :succeeded, :enter => :initiate_success

	aasm_event :timeout do
		transitions :from => :waiting, :to => :timedout
	end

	aasm_event :proceed do
		transitions :from => [ :failed, :waiting ], :to => :proceed
	end

	aasm_event :succeed do
		transitions :from => [ :proceed, :waiting ], :to => :succeeded
	end

	aasm_event :wait do
		transitions :from => :proceed, :to => :waiting
	end

	aasm_event :fail do
		transitions :from => [ :proceed, :waiting ], :to => :failed
	end

	def account() instance.provider_account if instance; end

	def data() self[:parameter]; end
	def data=(value)
		self.update_attribute(:parameter, value)
	end
	
  def can_proceed?
    failed? || waiting?
  end
  
	def max_attempts() 1; end
	def steps() []; end

	def timeout_in(seconds)
		self.update_attribute(:timeout_at, Time.now + seconds)
	end

	def timeout_reset()
		self.update_attribute(:timeout_at, nil)
	end

	def reentrant_timeout!()
		if not max_attempts_exceeded?
			self[:attempts] += 1
			self[:current_step] -= 1
			timeout_reset
			proceed!
		else
			timeout!
		end
		save
	end

	def server()
		return nil if instance.server_id.nil?
		return Server.find(instance.server_id)
	end
	
	# Factory to create instances of subclasses
	def self.factory(type, *params)
		class_name = type.nil? ? 'Operation' : type

		# make sure the class is included first, and don't fail on error loading library
		require class_name.underscore rescue false

		_class = class_name.constantize rescue nil
		if not _class.nil? and _class.name == class_name
			return _class.new(*params)
		end

		# fallback to operation base
		return Operation.new(params)
	end

	def class_type=(value) self[:type] = value; end
	def class_type() return self[:type]; end

	# sort, search and paginate parameters
	def self.per_page
		10
	end

    def self.find_all_by_parent(parent, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
		send("find_all_by_#{ parent.class.to_s.underscore }", parent, search, page, extra_joins, extra_conditions, sort, filter)
	end

	def self.find_all_by_server(server, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
		joins = [
			'INNER JOIN instances ON instances.id = operations.instance_id',
		] + [extra_joins].flatten.compact

		conditions = [ 'instances.server_id = ?', (server.is_a?(Server) ? server.id : server) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
  
		self.search(search, page, joins, conditions, sort, filter)
	end

    def self.find_all_by_server_task(server_task, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'server_task_id = ?', (server_task.is_a?(ServerTask) ? server_task.id : server_task) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    self.search(search, page, joins, conditions, sort, filter)
    end
  
  def self.sort_fields
    %w(name type instance_id state attempts result_code result_message created_at timeout_at)
  end

  def self.search_fields
    %w(name type instance_id result_code result_message)
  end

  def self.label
    'Operation'
  end

	def self.is_schedulable?
		true 
    end

    def task_verify_message
        ''
    end
    
protected

	def initiate_proceed() timeout_reset(); end
	def initiate_timeout(); end
	def initiate_failure(); end
	def initiate_success(); end
end
