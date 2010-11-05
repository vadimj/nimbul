class Cluster < BaseModel
  include AASM
	behavior :service
  
	service_parent_relationship :provider_account
	service_child_relationship :servers

	belongs_to :provider_account
  
	has_and_belongs_to_many :users
	has_and_belongs_to_many :cloud_resources
  
	has_many :cluster_parameters, :dependent => :destroy
	has_many :servers, :dependent => :destroy, :include => :server_profile_revision

	# auditing
	has_many :logs, :class_name => 'AuditLog', :dependent => :nullify
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

 	validates_presence_of :provider_account_id, :name
	validates_uniqueness_of :name, :scope => :provider_account_id
	validates_associated :cluster_parameters

	after_update :save_cluster_parameters
	attr_accessor :should_destroy
	
  aasm_column :state
  aasm_initial_state :active

  aasm_state :active
  aasm_state :maintenance, :enter => :initiate_maintenance

  aasm_event :activate do transitions :from => [ :active, :maintenance ], :to => :active; end
  aasm_event :maintain do transitions :from => :active, :to => :maintenance; end

	include TrackChanges # must follow any before filters

	def zones
		self.provider_account.zones
	end
	
	def addresses
		self.cloud_resources.find(:all, :conditions =>["type = 'CloudAddress'"])
	end

	def volumes
		self.cloud_resources.find(:all, :conditions =>["type = 'CloudVolume'"])
	end

	def snapshots
		self.cloud_resources.find(:all, :conditions =>["type = 'CloudSnapshot'"])
	end
	
	def should_destroy?
		should_destroy.to_i == 1
	end

	def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
		joins = []
		joins = joins + extra_joins unless extra_joins.blank?

		conditions = [ 'provider_account_id = ?', (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
		unless extra_conditions.blank?
		extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
  
		search(search, page, joins, conditions, sort, filter)
	end
  
	# this method is used by find_all_by_user, count_all_by_user and search_by_user in the searchable behavior
	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		joins = [
			'INNER JOIN provider_accounts ON provider_accounts.id = '+table_name()+'.provider_account_id',
		]
		conditions = ['1=0']
		if user.has_role?("admin")
			conditions = []
		else
			cluster_conditions = ['1=0']
			unless user.provider_accounts.empty?
				cluster_conditions << table_name()+".provider_account_id IN (#{user.provider_accounts.collect{|a| a.id}.join(',')})"
			end
			unless user.clusters.empty?
				cluster_conditions << table_name()+".id IN (#{user.clusters.collect{|c| c.id}.join(',')})"
			end
			conditions[0] = "(#{cluster_conditions.join(' OR ')})"
		end
    
		joins = joins + extra_joins unless extra_joins.blank?

		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
    
		order = 'provider_accounts.name, '+table_name()+'.name' if order.blank?

		options.merge!({
			:joins => joins,
			:conditions => conditions,
			:order => order,
		})

		return options        
	end
  
  def save_cluster_parameters
    cluster_parameters.each do |i|
      if i.should_destroy?
        i.destroy
      else
        i.save
      end
    end
  end

  def cluster_parameter_attributes=(cluster_parameter_attributes)
      cluster_parameter_attributes.each do |attributes|
          if attributes[:id].blank?
              cluster_parameters.build(attributes)
          else
              cluster_parameter = cluster_parameters.detect { |c| c.id == attributes[:id].to_i }
              cluster_parameter.attributes = attributes
          end
      end
  end

  def set_cluster_parameter(name, value, readonly = nil)
      parameter = cluster_parameters.detect{ |p| p.name == name }
      if parameter
          parameter.update_attribute( :value, value )
          parameter.update_attribute( :is_readonly, readonly ) unless readonly.nil?
      else
          parameter = cluster_parameters.build({
              :name => name,
              :value => value,
              :is_readonly => readonly.nil? ? false : true
          })
      end
      parameter.save
  end

  def get_cluster_parameter(name)
      parameter = cluster_parameters.detect { |p| p.name == name }
      return nil if parameter.nil?
      return parameter.value
  end

  def instances
      Instance.find_all_by_server_id(servers.collect{ |s| s.id })
  end

  # sort, search and paginate parameters
  def self.per_page
     10
  end

  def self.sort_fields
      %w(provider_account_id name description)
  end

  def self.search_fields
      %w(name description)
  end
end
