class CloudResource < BaseModel
    belongs_to :provider_account
    belongs_to :zone
    belongs_to :instance
    
    has_and_belongs_to_many :clusters
    
    has_many :server_resources, :dependent => :nullify
    has_many :instance_resources, :dependent => :nullify
    has_many :instance_addresses, :class_name => 'InstanceAddress'
    has_many :instance_volumes, :class_name => 'InstanceVolume'

    attr_accessor :should_destroy, :status_message, :destroyed
    
    validates_presence_of :name, :provider_account_id
    validates_uniqueness_of :name, :scope => [ :provider_account_id, :type ]

    before_destroy :ensure_no_usage
	after_destroy :mark_as_destroyed
	
	include TrackChanges # must follow any before filters
	
	def class_type=(value) self[:type] = value; end
	def class_type() return self[:type]; end
	def short_type
		self[:type].underscore.gsub('cloud_','')
	end
	def short_types
		self[:type].tableize.gsub('cloud_','')
	end

	def name_zone_state(separator=' - ')
		desc = ''
		desc << name
		desc << separator+self.zone.name unless zone_id.blank?
		desc << separator+state unless state.blank?
	end

	def cloud_id_zone_state(separator=' - ')
		desc = ''
		desc << cloud_id
		desc << separator+self.zone.name unless zone_id.blank?
		desc << separator+state unless state.blank?
	end

	def ensure_no_usage
		unless self.server_resources.empty?
			self.errors.add(:cloud_id, "#{self.name} - can't destroy, there are servers using this resource.")
			raise ActiveRecord::Rollback
		end
		unless self.instance_resources.empty?
			self.errors.add(:cloud_id, "#{self.name} - can't destroy, there are instances using this resource.")
			raise ActiveRecord::Rollback
		end
	end
	
	def mark_as_destroyed
	    self.destroyed = true
	end

    def should_destroy?
        should_destroy.to_i == 1
    end
    
    def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'cloud_resources.type = ? AND provider_account_id = ?', self.to_s, (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    search(search, page, joins, conditions, sort, filter, include)
    end
  
    def self.search_by_cluster(cluster, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
	    joins = [
	  	    'INNER JOIN cloud_resources_clusters ON cloud_resources_clusters.cloud_resource_id = cloud_resources.id',
	    ]
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'cloud_resources.type = ? AND cloud_resources_clusters.cluster_id = ?', self.to_s, (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
        search(search, page, joins, conditions, sort, filter, include)
    end
  
	# by default - find all resources visible to user through clusters
	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		conditions = ['1=0']
		if user.has_role?("admin")
			joins = []
			conditions = []
		else
			joins = [
				'INNER JOIN cloud_resources_clusters ON cloud_resources_clusters.cloud_resource_id = '+table_name()+'.id'
			]
			local_conditions = ['1=0']
			clusters = Cluster.find_all_by_user(user)
			unless clusters.empty?
				local_conditions << "cloud_resources_clusters.cluster_id IN (#{clusters.collect{|c| c.id}.uniq.join(',')})"
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

    def self.sort_fields
        %w(zone_id provider_account_id cloud_id name state create_time size parent_cloud_id is_enabled start_time progress owner_id description server_resources_count instance_resources_count cloud_instance_id)
    end

    def self.search_fields
        %w(cloud_id name parent_cloud_id cloud_instance_id description)
    end

    def self.filter_fields
        %w(state owner_id)
    end
    
    def self.classes_and_resources(cloud_resources, mount_types=[])
		cloud_resources =  cloud_resources.is_a?(Array) ? cloud_resources : [ cloud_resources ]
		resource_classes = []
		resources = []

		mount_type_lookup = {}
		unless mount_types.empty?
			mount_types.each do |mt|
				cloud_resource_types = mt.value.constantize.cloud_resource_types
				cloud_resource_types.each do |crt|
					mtl = mount_type_lookup[crt] || []
					mtl << mt.value
					mount_type_lookup[crt] = mtl
				end
			end
		end
		
		cloud_resources.each do |resource_group|
			# flatten the structure
			if resource_group.is_a?(Array)
				resource_group.sort!{ |a,b| a.name.downcase <=> b.name.downcase }
			else
				resource_group = [ resource_group ]
			end
			# collect resources replacing resource class with mount type if necessary
			resource_group.each do |r|
				if mount_type_lookup.empty?
					resources << GroupLabelValueFilter.new(r.class_type, r.name_zone_state, r.id, (r.zone_id.nil? ? '' : r.zone_id))
				elsif !mount_type_lookup[r.class_type].nil?
					mount_type_lookup[r.class_type].each do |mtl|
						resources << GroupLabelValueFilter.new(mtl, r.name_zone_state, r.id, (!mtl.constantize.care_about_zone? || r.zone_id.nil? ? '' : r.zone_id))
					end
				end
			end
		end
		
		# collect classes
		resources.each do |r|
			unless resource_classes.collect{|c| c.value}.include?(r.group)
				resource_classes << LabelValue.new(r.group.gsub('Cloud',''), r.group)
			end
		end
		
		yield resource_classes, resources
    end
    
    def self.server_resource_type(cloud_resource_type=nil)
		cloud_resource_type ||= self.to_s
		cloud_resource_type.gsub('Cloud','Server')
    end
    
    def self.default_mount_type
		raise "default_mount_type should be overwritten in subclasses of CloudResource"
    end
    
	def available?
	end

	def allocate!
	end
	
	def release!
	end
	
	def snapshot!
	end
	
	def delete!
	end
	
    def attach!(instance, force_allocation=false, mount_point=nil)
		# check to see if this resource is already attached to the instance
		return true if instance.instance_id == self.cloud_instance_id
		
		# check to see if this resource is attached to another instance
		unless self.instance_id.blank? or force_allocation
			self.errors.add(:instance_id, "currently attached to #{instance.name}")
			return false
		end
		
		# detach the resource if required
		if !self.instance_id.blank? and force_allocation
			unless self.detach!(force_allocation)
				self.errors.add(:instance_id, "failed to detach from #{self.instance.name}")
				return false
			end
		end
		
		# attach the resource
        begin
            if Ec2Adapter.attach(self, instance, mount_point)
				attrs = {
					:cloud_instance_id => instance.instance_id,
					:instance_id => instance.id,
					:state => 'in-use',
				}
				self.update_attributes(attrs)
				return true
            else
	            self.errors.add(:state, "failed to attach #{self.cloud_id} to #{instance.instance_id} [#{instance.id}]")
				return false
            end
        rescue
            self.errors.add(:state, "failed to attach #{self.cloud_id} to #{instance.instance_id} [#{instance.id}]: #{$!}")
            return false
        end
        
        return true
    end
    
    def detach!(force=false)
		# detach the resource
        begin
            if Ec2Adapter.detach(self, force)
				attrs = {
					:cloud_instance_id => nil,
					:instance_id => nil,
					:state => 'available',
				}
				self.update_attributes(attrs)
				return true
            else
	            self.errors.add(:state, "failed to detach #{self.cloud_id} from #{instance.instance_id} [#{instance.id}]")
				return false
            end
        rescue
            self.errors.add(:state, "failed to detach #{self.cloud_id} from #{instance.instance_id} [#{instance.id}]: #{$!}")
            return false
        end
        
        return true
    end
end
