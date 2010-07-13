class AutoScalingTrigger < BaseModel
    belongs_to :auto_scaling_group
	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

    validates_presence_of :name, :measure_name, :statistic, :period_value, :period_units, :lower_threshold, :lower_breach_scale_increment_value, :lower_breach_scale_increment_units, :upper_threshold, :upper_breach_scale_increment_value, :upper_breach_scale_increment_units, :breach_duration_value, :breach_duration_units
    validates_format_of :name, :with => /^[A-Za-z\d_]+$/, :message => 'must be an alphanumeric string'
    validates_uniqueness_of :name, :scope => [ :auto_scaling_group_id ], :message => 'must be unique within the scope of the associated AutoScalingGroup'

	attr_accessor :period_value, :period_units
	attr_accessor :lower_breach_scale_increment_action, :lower_breach_scale_increment_value, :lower_breach_scale_increment_units
	attr_accessor :upper_breach_scale_increment_action, :upper_breach_scale_increment_value, :upper_breach_scale_increment_units
	attr_accessor :breach_duration_value, :breach_duration_units
	attr_accessor :namespace

	validates_numericality_of :period, :breach_duration, :lower_threshold, :upper_threshold,
		:integer_only => true,
		:allow_nil => true,
		:greater_than => 0,
		:message => 'must be an integer greater than 0'
	validates_inclusion_of :period_units,
		:in => AS_TRIGGER_PERIOD_UNITS,
		:allow_nil => true,
		:message => "must be one of #{AS_TRIGGER_PERIOD_UNITS.join(', ')}"
	validates_inclusion_of :breach_duration_units,
		:in => AS_TRIGGER_BREACH_DURATION_UNITS,
		:allow_nil => true,
		:message => "must be one of #{AS_TRIGGER_BREACH_DURATION_UNITS.join(',')}"
		
	before_save :parse_values_from_ui

	include TrackChanges # must follow any before filters

	def parse_values_from_ui
		unless self.period_value.blank? and self.period_units.blank?
			p = self.period_value.to_i
			self.period = p.send(self.period_units).to_i
		end
		unless self.breach_duration_value.blank? and self.breach_duration_units.blank?
			p = self.breach_duration_value.to_i
			self.breach_duration = p.send(self.breach_duration_units).to_i
		end
		unless self.lower_breach_scale_increment_action.blank? and self.lower_breach_scale_increment_value.blank? and self.lower_breach_scale_increment_units.blank?
			self.lower_breach_scale_increment = ''
			self.lower_breach_scale_increment = '-' if self.lower_breach_scale_increment_action == 'decrease'
			self.lower_breach_scale_increment += self.lower_breach_scale_increment_value.to_s
			self.lower_breach_scale_increment += '%' if self.lower_breach_scale_increment_units == '%'
		end
		unless self.upper_breach_scale_increment_action.blank? and self.upper_breach_scale_increment_value.blank? and self.upper_breach_scale_increment_units.blank?
			self.upper_breach_scale_increment = ''
			self.upper_breach_scale_increment = '-' if self.upper_breach_scale_increment_action == 'decrease'
			self.upper_breach_scale_increment += self.upper_breach_scale_increment_value.to_s
			self.upper_breach_scale_increment += '%' if self.upper_breach_scale_increment_units == '%'
		end
	end

	def parse_ui_from_values
		unless self.period.blank?
			AS_TRIGGER_PERIOD_UNITS.sort{|a,b| 1.send(a) <=> 1.send(b)}.each do |unit|
				value =( self.period / 1.send(unit).to_i )
				break unless value > 0
				self.period_value = value
				self.period_units = unit
			end
		end
		unless self.breach_duration.blank?
			AS_TRIGGER_BREACH_DURATION_UNITS.sort{|a,b| 1.send(a) <=> 1.send(b)}.each do |unit|
				value =( self.breach_duration / 1.send(unit).to_i )
				break unless value > 0
				self.breach_duration_value = value
				self.breach_duration_units = unit
			end
		end
		unless self.lower_breach_scale_increment.blank?
			self.lower_breach_scale_increment_action = self.lower_breach_scale_increment.include?('-') ? 'decrease' : 'increase'
			self.lower_breach_scale_increment_value = self.lower_breach_scale_increment.gsub('-','').gsub('%','')
			self.lower_breach_scale_increment_units = self.lower_breach_scale_increment.include?('%') ? '%' : 'instances'
		end
		unless self.upper_breach_scale_increment.blank?
			self.upper_breach_scale_increment_action = self.upper_breach_scale_increment.include?('-') ? 'decrease' : 'increase'
			self.upper_breach_scale_increment_value = self.upper_breach_scale_increment.gsub('-','').gsub('%','')
			self.upper_breach_scale_increment_units = self.upper_breach_scale_increment.include?('%') ? '%' : 'instances'
		end
	end
	
	def parent_active?
		return true if auto_scaling_group.try :active?
		return false
	end
	
	def parent_disabled?
		return true if auto_scaling_group.try :disabled?
		return false
	end

	def disabled?
		( state == 'disabled' )
	end
	
	def active?
		( state == 'active' )
	end
	
	def can_activate?
		parent_active? ? true : false
	end

	def can_disable?
		parent_active? ? true : false
	end
	
    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name launch_configuration_name image_id instance_type created_at server_id state)
    end

    def self.search_fields
        %w(name launch_configuration_name image_id)
    end
    
    def update_cloud
		return true unless self.active?
		activate!
	end
    
    def activate!
        begin
			AsAdapter.create_update_auto_scaling_trigger(self)
			self.update_attribute(:state, :active)
			return true
        rescue Exception => e
			msg = "Failed to activate Auto Scaling Trigger '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, msg)
			return false
        end
	end

    def disable!
		begin
			AsAdapter.delete_auto_scaling_trigger(self)
			self.update_attribute(:state, :disabled)
			return true
        rescue Exception => e
			msg = "Failed to disable Auto Scaling Trigger '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, msg)
			return false
        end
    end
end
