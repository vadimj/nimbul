require 'aasm'

class AutoScalingGroup < BaseModel
    include AASM

    belongs_to :provider_account
    belongs_to :launch_configuration

    has_and_belongs_to_many :zones, :uniq => true
    has_and_belongs_to_many :load_balancers, :uniq => true

	has_many :instances, :dependent => :nullify
    has_many :auto_scaling_triggers, :dependent => :destroy

	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    validates_format_of :name, :with => /^[A-Za-z\d]+$/, :message => 'must be an alphanumeric string'
    validates_length_of :name, :maximum => 256, :message => 'must contain less than 256 alphanumeric characters'
    validates_presence_of :launch_configuration_id, :name, :min_size, :max_size, :desired_capacity, :cooldown
    validates_uniqueness_of :name, :scope => [ :provider_account_id ], :message => 'must be unique within your Amazon Web Services (AWS) account'
    validates_numericality_of :min_size, :max_size, :desired_capacity, :cooldown,
		:only_integer => true,
		:greater_tan => 0,
		:message => 'must be an integer greater than 0'
    validate :valid_size_and_capacity?

    attr_accessor :should_destroy, :status_message
    
    # aasm
    aasm_column :state
    aasm_initial_state :disabled
    aasm_state :active
    aasm_state :disabling
    aasm_state :disabled

    aasm_event :activate do
        transitions :from => [ :disabling, :disabled ], :to => :active, :guard => :cloud_activate?
    end

    aasm_event :disable do
        transitions :from => [ :active ], :to => :disabling, :guard => :cloud_disable?
    end
    
    aasm_event :remove do
		transitions :from => [ :active, :disabling ], :to => :disabled, :guard => :cloud_remove?
    end

	include TrackChanges # must follow any before filters

    def should_destroy?
        should_destroy.to_i == 1
    end
    
    def can_use_more_auto_scaling_triggers?
		( 0 == self.auto_scaling_triggers.length )
    end
    
	def valid_size_and_capacity?
		unless self.min_size.nil? and self.max_size.nil?
			if self.min_size > self.max_size
				self.errors.add(:min_size, "should be less or equal to Maximum Size")
			end
			unless self.desired_capacity.nil?
				if self.desired_capacity < self.min_size
					self.errors.add(:desired_capacity, "should be greater or equal to Minimum Size")
				end
				if self.desired_capacity > self.max_size
					self.errors.add(:desired_capacity, "should be less or equal to Maximum Size")
				end
			end
		end
	end

    def update_cloud
		return true unless self.active?
        begin
            AsAdapter.update_auto_scaling_group(self)
        rescue Exception => e
			msg = "Couldn't update Auto Scaling Group '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, msg)
			raise ActiveRecord::Rollback
        end
        return true
	end
    
    def cloud_activate?()
		lc_active = (launch_configuration.active? or launch_configuration.activate!)
		group_active = AsAdapter.create_auto_scaling_group(self)
		triggers_active = true
		self.auto_scaling_triggers.each do |trigger|
			triggers_active = triggers_active and trigger.activate!
		end
        return (lc_active and group_active and triggers_active)
    end
    
    def cloud_disable?()
		begin
			AsAdapter.disable_auto_scaling_group(self)
			self.auto_scaling_triggers.update_all({:state => :disabled})
        rescue Exception => e
			msg = "Couldn't disable Auto Scaling Group '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, msg)
			raise ActiveRecord::Rollback
        end
        return true
    end

    def cloud_remove?()
		if AsAdapter.delete_auto_scaling_group(self)
			self.auto_scaling_triggers.update_all({:state => :disabled})
		else
			return false
		end
    end

    def has_zone?(zone)
		self.zones.include?(zone)
    end

    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name min_size max_size desired_capacity cooldown state)
    end

    def self.search_fields
        %w(name state)
    end
end
