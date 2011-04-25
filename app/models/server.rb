class Server < BaseModel
  PARAMETER_PRIORITY = [
    ServerProfileRevisionParameter,
    ClusterParameter,
    ProviderAccountParameter
  ]
      
	behavior :service

	service_parent_relationship :cluster
	service_child_relationship :none

	belongs_to :cluster, :counter_cache => true, :include => :provider_account
	belongs_to :server_profile_revision
  
	has_and_belongs_to_many :security_groups, :order => :name, :uniq => true
	has_many :instances, :dependent => :nullify

	has_many :server_user_accesses
	has_many :users, :through => :server_user_accesses

	has_and_belongs_to_many :dns_hostnames, :join_table => :dns_hostname_assignments, :select => 'dns_hostnames.*'
	has_many :dns_hostname_assignments, :dependent => :destroy
	
	has_many :tasks, :as => :taskable, :dependent => :destroy
	has_one :default_resource_bundle, :class_name => 'ResourceBundle', :conditions => { :is_default => true }, :include => [ :zone, :server_resources, :addresses, :volumes, :instance ]
	has_many :resource_bundles, :dependent => :destroy, :order => 'position', :include => [ :zone, :server_resources, :addresses, :volumes, :instance ]
	has_many :zones, :through => :resource_bundles, :order => :name, :uniq => true, :readonly => true
	has_many :addresses, :through => :resource_bundles, :uniq => true
	has_many :volumes, :through => :resource_bundles, :uniq => true
	
	# auditing
	has_many :logs, :class_name => 'AuditLog', :dependent => :nullify
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :cluster_id, :message => 'there is already a Server with this name in the Cluster'

	after_save :save_server_user_accesses, :update_instances
	before_destroy :ensure_no_usage, :update_instances

	attr_accessor :should_destroy, :status_message

	include TrackChanges # must follow any before filters

	# overwriting this method to make sure there is only one default bundle
	def default_resource_bundle=(resource_bundle)
		resource_bundles.update_all( :is_default => false )
		resource_bundles.detect{ |rb| rb.id == resource_bundle.id}.update_attribute(:is_default, true)
	end
	
	def next_available_resource_bundle(zone=nil)
		rb = self.resource_bundles.detect{ |rb| rb.instance_id.nil? and ( zone.nil? or rb.zone_id == zone.id ) }
		rb = self.default_resource_bundle if rb.nil?
		return rb
	end
	
	def has_resource_bundles?
		!resource_bundles.empty?
	end
	
	def ensure_no_usage
		unless self.instances.empty?
			self.errors.add(:id, "#{self.name} - can't delete, there are instances associated with this server. Terminate all associated instances first.")
			raise ActiveRecord::Rollback
		end
	end
	
	# get count of available resource bundles, fill out with default rb if necessary
	def available_resource_bundles(count)
		rbs = self.resource_bundles.collect{ |rb| rb if rb.instance_id.blank? }.compact
		if (rbs.size < count) and !self.default_resource_bundle.nil?
			rbs += [ self.default_resource_bundle ] * ( count - rbs.size )
		end
		return rbs
	end
	
	def available_resources(zone_id=nil)
	    # grab ids of all addresses that have been allocated for this server
	    allocated_address_ids = []
	    self.resource_bundles.each do |rs|
			allocated_address_ids += rs.server_resources.collect{ |v| v.cloud_resource_id if !v.cloud_resource_id.nil? and v.class_type == 'ServerAddress' }.compact
		end
		cluster = self.cluster
        z = cluster.zones
		a = cluster.addresses.collect{ |a| a if !allocated_address_ids.include?(a.id) }.compact
		v =	cluster.volumes.collect{ |v| v if (zone_id.blank? || zone_id == v.zone_id) }.compact
		s = cluster.snapshots
		yield z, a, v, s
	end
	
	def available_zones(zone_id=nil)
		available_resources do |z,a,v,s|
			z
		end
	end

	def available_addresses(zone_id=nil)
		available_resources do |z,a,v,s|
			a
		end
	end
	
	def available_volumes(zone_id=nil)
		available_resources do |z,a,v,s|
			v
		end
	end
	
	def available_snapshots(zone_id=nil)
		available_resources do |z,a,v,s|
			s
		end
	end
	
	def can_use_more_of?(resource_bundle_type)
		return true if resource_bundle_type == 'ResourceBundle'
		return false
	end
	
	def should_destroy?
		should_destroy.to_i == 1
	end

	def publishable?
		return false unless startable?
		return false if ServerImage.find_by_image_id(self.image_id).try(:location).nil?
		return true
	end
	
	# has bare minimum attributes set allowing for start of instances
	def startable?
		return false if self.key_name.blank? || self.instance_type.blank? || self.image_id.blank? || self.security_groups.nil?
		return true
	end
	
	def startup_script
    return '' unless self.server_profile_revision
		self.server_profile_revision.startup_script
	end
	
	def server_parameters
		return [] unless self.server_profile_revision
		self.server_profile_revision.server_profile_revision_parameters
	end

	def image_id
		return nil unless self.server_profile_revision
		self.server_profile_revision.image_id
	end

	def instance_type
		return nil unless self.server_profile_revision
		self.server_profile_revision.instance_type
	end

	def update_instances
		Instance.update_all( ['server_name=?', name], ['server_id=?', id ] )
	end

	def to_s
		name
	end

	def server_user_access_attributes=(server_user_access_attributes)
		server_user_access_attributes.each do |attributes|
			if attributes[:id].blank?
				# make sure there is not access rule with the same user_id and server_user
				server_user_access = server_user_accesses.detect { |c| c.user_id == attributes[:user_id].to_i and c.server_user == attributes[:server_user].to_s }
				server_user_accesses.build(attributes) unless server_user_access
			else
				server_user_access = server_user_accesses.detect { |c| c.id == attributes[:id].to_i }
				server_user_access.attributes = attributes unless server_user_access.nil?
			end
		end
	end

	def set_server_parameter(name, value, readonly = nil )
		parameter = server_parameters.detect{ |p| p.name == name }
		if parameter
			parameter.update_attribute( :value, value )
			parameter.update_attribute( :is_readonly, readonly ) unless readonly.nil?
		else
			parameter = server_parameters.build({
				:name => name,
				:value => value,
				:is_readonly => readonly.nil? ? false : true
			})
		end
		parameter.save
	end

	def get_server_parameter(name)
		parameter = server_parameters.detect { |p| p.name == name }
		return nil if parameter.nil?
		return parameter.value
	end

  def get_parameter(name)
    parameters[name].value rescue nil
  end
  
  #
  # Retreives the combined parameter list of the Provider Account, Cluster and this Server
  # and provides a [] access method which retreives keys based on Parameter Class Priority
  #
  def parameters
    _parameters = (
      self.cluster.provider_account.provider_account_parameters +
      self.cluster.cluster_parameters +
      self.server_parameters
    )
    _parameters.class_eval(<<-EOS, __FILE__, __LINE__)
      # order of priority (highest to lowest): server -> cluster -> provider account
      alias :__array_access_orig :[]
      def [](key)
        return self.__array_access_orig(key) if key.is_a? Integer
        matches = self.select { |p| p.name == key }
        return case matches.size
          when 0
            nil
          when 1
            matches.first
          else
            matches.sort_by {|m| Server::PARAMETER_PRIORITY.index(m.class) }.first
        end
      end
    EOS
    _parameters
  end
  
	def save_server_user_accesses
		server_user_accesses.each do |c|
			if c.should_destroy?
				c.destroy
			else
				c.save(false)
			end
		end
	end
  
	def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		joins = [
			'INNER JOIN clusters ON clusters.id = servers.cluster_id',
		] + [extra_joins].flatten.compact

		conditions = [ 'clusters.provider_account_id = ?', (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
  
		search(search, page, joins, conditions, sort, filter, include)
	end

	def self.search_by_cluster(cluster, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		joins = [] + [extra_joins].flatten.compact
		
		conditions = [ 'cluster_id = ?', (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ].flatten
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
		
		search(search, page, joins, conditions, sort, filter, include)
	end
  
	def self.search_by_security_group(security_group, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		joins = [
			'INNER JOIN security_groups_servers ON security_groups_servers.server_id = servers.id',
		] + [extra_joins].flatten.compact

		conditions = [ 'security_groups_servers.security_group_id = ?', (security_group.is_a?(SecurityGroup) ? security_group.id : security_group) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ].flatten
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
  
		search(search, page, joins, conditions, sort, filter, include)
	end

	# this method is used by find_all_by_user, count_all_by_user and search_by_user in the searchable behavior
	def self.options_for_find_by_user(user, options={})
	  user = User.find_by_id(user) if user.is_a? Fixnum
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		conditions = ['1=0']
		if user.has_role?("admin")
			joins = []
			conditions = []
		else
			joins = [
				'INNER JOIN clusters ON clusters.id = '+table_name()+'.cluster_id INNER JOIN provider_accounts ON provider_accounts.id = clusters.provider_account_id',
			]
			local_conditions = ['1=0']
			unless user.provider_accounts.empty?
				local_conditions << "clusters.provider_account_id IN (#{user.provider_accounts.collect{|a| a.id}.join(',')})"
			end
			unless user.clusters.empty?
				local_conditions << "clusters.id IN (#{user.clusters.collect{|c| c.id}.join(',')})"
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
	
	def self.per_page
		10
	end

	#%w(name server_profile_revision_id key_name zone_id volume_id public_ip)
	def self.sort_fields
		%w(name key_name server_profile_revision_id cluster_id)
	end

	def self.search_fields
		%w(name key_name)
	end

	#
	# control functions
	#
	def start!(count=1, options={})
		instances = []
		
        begin
            instances = Ec2Adapter.run_instances(self, count, options)
        rescue Exception => e
			msg = "Failed to start server '#{self.name}' [#{self.id}]: #{e.message}"
			Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
			self.errors.add(:state, "#{msg}")
        end
        
        return instances
	end
	
    def add_user_key(user_key, server_user)
	self.instances.each do |instance|
	    next if not instance.running?
	    instance.operations << Operation.factory(
	        'Operation::SshKeys::Add',
		:args => {
		    :local_user_id => user_key.user_id,
		    :server_user => server_user,
		    :public_key => user_key.public_key,
		    :hash_of_public_key => user_key.hash_of_public_key,
		}
	    )
	end
    end

    def delete_user_key(user_key, server_user)
	self.instances.each do |instance|
	    next if not instance.running?
	    instance.operations << Operation.factory(
	        'Operation::SshKeys::Delete',
		:args => {
		    :local_user_id => user_key.user_id,
		    :server_user => server_user,
		    :public_key => user_key.public_key,
		    :hash_of_public_key => user_key.hash_of_public_key,
		}
	    )
	end
    end
end
