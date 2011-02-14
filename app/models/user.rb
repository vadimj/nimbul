class User < BaseModel
  include Authentication
  include Authentication::ByCookieToken
  include Authentication::UserAbstraction

  has_and_belongs_to_many :provider_accounts
  has_and_belongs_to_many :security_groups
  has_and_belongs_to_many :clusters

  has_many :server_profile_user_accesses, :dependent => :destroy
  has_many :server_profiles, :through => :server_profile_user_accesses

  has_many :logs, :foreign_key => :author_id, :class_name => 'AuditLog', :dependent => :nullify

  has_many :user_keys, :dependent => :destroy

  set_inheritance_column :user_type
  validates_presence_of  :user_type
  validates_associated :user_keys
    
  after_save :save_user_keys

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # Add identity_url if you want users to be able to update their OpenID identity
  attr_accessible :login, :email, :name, :password, :password_confirmation, :invitation_token, :time_zone, :user_key_attributes
  attr_accessor :login_and_name, :auth_type

  def save_user_keys
    user_keys.each do |i|
      if i.should_destroy?
        i.destroy
      else
        i.save
      end
    end
  end

  def user_key_attributes=(user_key_attributes)
    user_key_attributes.each do |attributes|
      if attributes[:id].blank?
        user_keys.build(attributes)
      else
        user_key = user_keys.detect { |c| c.id == attributes[:id].to_i }
        user_key.attributes = attributes
      end
    end
  end

    def login_and_name
        login + ' (' + name + ')'
    end
    
    def auth_type
		klass = self.class.to_s.sub(/User/, '')
		if klass == 'Site'
			'DB'
		elsif klass == 'Ldap'
			'LDAP'
		else
			klass
		end
    end

	def to_xml(options = {})
		default_only = []
		options[:only] = (options[:only] || []) + default_only
		super(options)
	end
	
	def enable!
		self.update_attribute(:enabled, true)
	end
	
	def disable!
		self.update_attribute(:enabled, false)
	end

	def has_access?(o)
		send("has_#{ o.class.to_s.underscore }_access?", o)
	end
	
	def has_site_user_access?(u)
		has_user_access?(u)
	end
	
	def has_ldap_user_access?(u)
		has_user_access?(u)
	end
	
	def has_author_access?(a)
		has_user_access?(a)
	end

	def has_user_access?(u)
		# admin can access any user
		return true if has_role?("admin")
		( self.id == u.id )
	end
	
	def has_provider_account_access?(provider_account)
		return true if has_role?("admin")
		provider_account_id = provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account
		@provider_accounts_list ||= self.provider_accounts.collect(&:id)
		( @provider_accounts_list.include?(provider_account_id) )
	end

	def has_cluster_access?(cluster)
		return true if has_role?("admin")
		return true if has_provider_account_access?(cluster.provider_account_id)
		cluster_id = cluster.is_a?(Cluster) ? cluster.id : cluster
		@clusters_list ||= self.clusters.collect(&:id)
		( @clusters_list.include?(cluster_id) )
	end

	def has_cloud_resource_access?(cresource)
		return true if has_role?('admin')
		return true if has_provider_account_access?(cresource.provider_account)
		@resource_clusters ||= cresource.clusters.collect(&:id)
		@user_clusters ||= self.clusters.collect(&:id)
		(@resource_clusters & @user_clusters).length > 0
	end

	def has_volume_access?(volume)
		return true if has_role?("admin")
		return true if has_provider_account_access?(volume.provider_account)
        return false
	end

	def has_snapshot_access?(snapshot)
		return true if has_role?("admin")
		return true if has_provider_account_access?(snapshot.provider_account)
        return false
	end

	def has_address_access?(address)
		return true if has_role?("admin")
		return true if has_provider_account_access?(address.provider_account)
        return false
	end

	def has_firewall_rule_access?(firewall_rule)
		return true if has_role?("admin")
		return true if has_provider_account_access?(firewall_rule.provider_account)
        return false
	end

	def has_security_group_access?(security_group)
		return true if has_role?("admin")
		return true if has_provider_account_access?(security_group.provider_account)
        return false
	end
	
	def has_key_pair_access?(key_pair)
		return true if has_role?("admin")
		return true if has_provider_account_access?(key_pair.provider_account)
        return false
	end

	def has_server_image_access?(server_image)
		return true if has_role?("admin")
		return true if has_provider_account_access?(server_image.provider_account)
        return false
	end

	def has_launch_configuration_access?(launch_configuration)
		return true if has_role?("admin")
		return true if has_provider_account_access?(launch_configuration.provider_account)
        return false
	end

	def has_auto_scaling_group_access?(auto_scaling_group)
		return true if has_role?("admin")
		return true if has_provider_account_access?(auto_scaling_group.provider_account)
        return false
	end

	def has_auto_scaling_trigger_access?(auto_scaling_trigger)
		return true if has_role?("admin")
		return true if has_provider_account_access?(auto_scaling_trigger.auto_scaling_group)
        return false
	end

	def has_publisher_access?(publisher)
		return true if has_role?("admin")
		return true if has_provider_account_access?(publisher.provider_account)
        return false
	end

	def has_server_access?(server)
		return true if has_role?("admin")
		return true if has_cluster_access?(server.cluster)
        return false
	end

	def has_resource_bundle_access?(resource_bundle)
		return true if has_role?("admin")
		return true if has_server_access?(resource_bundle.server)
        return false
	end

	def has_task_access?(task)
		return true if has_role?("admin")
		return true if has_access?(task.taskable)
        return false
	end

	def has_instance_access?(instance)
		return true if has_role?("admin")
		return true if has_provider_account_access?(instance.provider_account)
        unless instance.server_id.nil?
            server = Server.find(instance.server_id, :include => [ :cluster ])
            return true if has_server_access?(server)
        end
        return false
	end

	def has_instance_resource_access?(instance_resource)
		return true if has_role?("admin")
		return true if has_instance_access?(instance_resource.instance)
		return false
	end

	def has_dns_hostname_access?(hostname)
		return true if has_role?("admin")
		return true if has_provider_account_access?(hostname.provider_account)
		unless hostname.servers.blank?
			# if the user has access to ALL servers with this this name
			# if no servers are assigned this name, then no access at this point
			hostname.servers.each do |s| 
				return true if ! s.cluster_id.blank? && has_cluster_access?(s.cluster) 
				return true if has_server_access?(s)
			end
		end
		return false
	end

	def has_dns_lease_access?(lease)
		return true if has_role?("admin")
		assignment = lease.dns_hostname_assignment
		return true if has_provider_account_access?(assignment.dns_hostname.provider_account) 
		unless assignment.server_id.blank?
			return true if has_cluster_access?(assignment.server.cluster)
			return true if has_server_access?(assignment.server)
		end
		unless lease.instance_id.blank?
			return true if has_instance_access?(lease.instance)
		end
		return false
	end

	def has_server_profile_access?(server_profile)
        # in this version we allow access to server profiles by default
        # TODO: make secure in the next version
        return true
		return true if has_role?("admin")
		return true if has_provider_account_access?(server_profile.provider_account)
		@server_profiles_list ||= self.server_profiles.collect(&:id)
		(@server_profiles_list.include?(server_profile.id) )
	end

    def has_server_profile_revision_access?(server_profile_revision)
        return has_server_profile_access?(server_profile_revision.server_profile)
    end

	def self.member_list(page)
		paginate :all,
			:per_page => 50, :page => page,
			:conditions => ['enabled = ? and activated_at IS NOT NULL', true],
			:order => 'login'
	end

    # sort, search and paginate parameters
	def self.per_page
		50
	end

    def self.sort_fields
        %w(login name email activated_at enabled user_type)
    end

    def self.search_fields
        %w(login name email user_type)
    end

end
