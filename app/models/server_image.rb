require 'aasm'

class ServerImage < BaseModel
	include AASM
	belongs_to :provider_account
    has_many :server_profile_revisions, :primary_key => :image_id, :foreign_key => :image_id
    has_many :launch_configurations, :dependent => :nullify

    set_inheritance_column :server_image_type

	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :provider_account_id
	validates_uniqueness_of :image_id, :scope => :provider_account_id, :message => 'There is already an Image with this AMI ID.'
	validates_uniqueness_of :location, :scope => :provider_account_id, :message => 'There is already an Image with this Manifest Path'
	validates_presence_of :image_id, :if => :image_id_and_location_are_blank, :message => 'You have to specify AMI ID (existing Images) or a Manifest Path (new Images)'
	validates_presence_of :location, :if => :image_id_and_location_are_blank, :message => 'You have to specify AMI ID (existing Images) or a Manifest Path (new Images)'
	
	attr_accessor :should_destroy, :status_message, :destroyed
	
    before_destroy :ensure_no_usage
	after_destroy :mark_as_destroyed
	
    def image_id_and_location_are_blank
		self.image_id.blank? and self.location.blank?
    end
    
	def ensure_no_usage
		unless self.server_profile_revisions.empty?
			self.errors.add(:name, "#{self.name} - can't destroy, there are server profiles using this server image.")
			raise ActiveRecord::Rollback
		end
	end

	def mark_as_destroyed
	    self.destroyed = true
	end
    
    def should_destroy?
        should_destroy.to_i == 1
    end

    def enable!
        update_attribute(:is_enabled, true)
    end

    def disable!
		if self.server_profile_revisions.empty?
			update_attribute(:is_enabled, false)
		else
			self.errors.add(:is_enabled, "Can't disable '#{self.name}' - there are server profiles using this server image.")
		end
    end

	# aasm
	aasm_column :state
	aasm_initial_state :unknown
	aasm_state :unknown
	aasm_state :available
	aasm_state :unavailable

	aasm_event :state_unknown do
		transitions :from => [ :unknown, :available, :unavailable ], :to => :unknown
	end

	aasm_event :make_available do
		transitions :from => [ :unknown, :available, :unavailable ], :to => :available
	end

	aasm_event :make_unavailable do
		transitions :from => [ :unknown, :available, :unavailable ], :to => :unavailable
	end
	
	def belongs_to_provider_account?(provider_account)
		account_id = provider_account.is_a?(ProviderAccount) ? provider_account.account_id : provider_account
		!self.owner_id.blank? and ( self.owner_id == account_id )
	end

	# fill out attributes from the Provider Account (e.g. when registering a new image
	def self.refresh(server_image)
		Ec2Adapter.refresh_server_image(server_image)
	end

	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		conditions = ['1=0']
		if user.has_role?("admin")
			joins = []
			conditions = []
		else
			joins = []
			local_conditions = ['1=0']
			clusters = Cluster.find_all_by_user(user)
			unless clusters.empty?
				local_conditions << table_name()+".provider_account_id IN (#{clusters.collect{|c| c.provider_account_id}.uniq.join(',')})"
			end
			conditions[0] = "(#{local_conditions.join(' OR ')})"
		end
    
		joins = joins + extra_joins unless extra_joins.blank?

		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
    
		order = table_name()+'.name' if order.blank?

		options.merge!({
			:joins => joins,
			:conditions => conditions,
			:order => order,
		})

		return options        
	end

    def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort = nil, filter=nil, include=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'provider_account_id = ?', (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    search(search, page, joins, conditions, sort, filter, include)
    end
    
    def allocate!
        begin
			if self.image_id
				Ec2Adapter.refresh_server_image(self)
			else
				Ec2Adapter.register_server_image(self)
			end
            self.save
        rescue
			if self.location
	            self.errors.add(:location, "#{$!}")
			else
	            self.errors.add(:image_id, "#{$!}")
			end
            self.status_message = "Failed to add server image: #{$!}"
            self.destroy
            return false
        end
        return true
	end

    def release!
        begin
            self.destroy
            if self.belongs_to_provider_account?(self.provider_account)
	            Ec2Adapter.deregister_image(self)
            end
        rescue
            self.errors.add(:id, "#{$!}")
            self.status_message = "Failed to deregister server image: #{$!}"
            return false
        end
        return true
    end

    def self.per_page
        10
    end

    def self.sort_fields
        %w(name image_id location architecture state owner_id is_public is_enabled provider_account_id)
    end

    def self.search_fields
        %w(name image_id location architecture)
    end

end
