class DnsLease < BaseModel

	ACTIVE   = 'isup'
	INACTIVE = 'isdown'
	
	belongs_to :instance
	belongs_to :dns_hostname_assignment, :include => { :server => { :cluster => :provider_account } }
	has_one :server, :through => :dns_hostname_assignment, :include => { :cluster => :provider_account } 
	
	validates_presence_of :dns_hostname_assignment_id, :idx
	validates_numericality_of :instance_id, :allow_nil => true

	def self.find_available(assignment)
		# get an unassigned lease with the lowest index that matches the given dns hostname assignment id
		self.first(
			:conditions => {
        :dns_hostname_assignment_id => assignment.id,
        :instance_id => nil
      },
			:order => 'idx ASC'
		)
	end
	
	def self.find_by_model(model, options = { :hostname => nil, :which => :all })
    hostname = DnsHostname.normalize_hostname(options.delete(:hostname), model) 
    conditions = {
      model.class.table_name.to_sym => { :id => model[:id] },
    }
    
    case options.delete(:which)
      when :used:
        conditions.merge!({:instance_id => (1)..(Instance.last[:id])})
      when :available: 
        conditions.merge!({:instance_id => nil })
      else
        # include both used and available
    end

    conditions.merge!({ :dns_hostnames => { :id => hostname[:id] }}) unless hostname.nil?
    
    all(
      :select => 'DISTINCT(dns_leases.id), dns_leases.*, dns_hostnames.name as name',
      :joins => {
        :dns_hostname_assignment => {
          :dns_hostname => :provider_account,
          :server => [ :instances, :cluster ]
        }
      },
      :conditions => conditions,
      :order => 'name ASC, idx ASC'
    )
	end
	
	def self.find_all_by_hostname(hostname, only_in_use = false)
    find_by_model 
    self.all(
      :select => 'DISTINCT(dns_leases.id), dns_leases.*, dns_hostnames.name as name',
      :joins => {
        :dns_hostname_assignment => :dns_hostname
      },
      :conditions => {
        :dns_hostnames => { :id => (hostname.is_a?(DnsHostname) ? hostname.id : hostname) }
      },
      :order => 'name ASC, idx ASC'
    )
	end

	def self.find_all_by_instance_id(instance, only_in_use = false)
		self.find_all_by_instance_id_and_hostname_id(instance, nil, only_in_use)
	end
	
	def self.find_all_by_instance_id_and_hostname_id(instance, hostname_id = nil, only_in_use = false)
    conditions = {
      :dns_leases => { :instance_id => instance.is_a?(Instance) ? instance.id : instance }
    }.merge!( (hostname_id.nil? ? {} : {:dns_hostnames => { :id => hostname_id }}) )

    self.all(
      :select => 'DISTINCT(dns_leases.id), dns_leases.*, dns_hostnames.name as name',
      :joins => {
        :dns_hostname_assignment => [
          :dns_hostname,
          { :server => :instances }
        ]
      },
      :conditions => conditions,
			:order => 'name ASC, idx ASC'
    )
	end
	
	def self.find_all_by_server_id(server, only_in_use = false)
		self.find_all_by_server_id_and_hostname_id(server, nil, only_in_use)
	end
	
	def self.find_all_by_server_id_and_hostname_id(server, hostname_id = nil, only_in_use = false)
    server = (server.is_a?(Server) ? server.id : server)
    conditions = {
      :servers => { :id => server }
    }.merge!( (hostname_id.nil? ? {} : { :dns_hostnames => { :id => hostname_id }}) )
    
		self.all(
			:select => 'dns_leases.*, dns_hostnames.name as name',
			:conditions => conditions,
      :joins => {
        :dns_hostname_assignment => [ :dns_hostname, :server ]
      },
			:order => 'name ASC, idx ASC'
		)
	end
	
	def self.find_all_by_cluster_id(cluster, only_in_use = false)
		self.find_all_by_cluster_id_and_hostname_id(cluster, nil, only_in_use)
	end
	
	def self.find_all_by_cluster_id_and_hostname_id(cluster, hostname_id = nil, only_in_use = false)
    cluster = (cluster.is_a?(Cluster) ? cluster.id : cluster)
    conditions = {
      :clusters => { :id => cluster }
    }.merge!( (hostname_id.nil? ? {} : { :dns_hostnames => { :id => hostname_id }}) )

		self.all(
			:select => 'dns_leases.*, dns_hostnames.name as name',
			:conditions => conditions,
			:joins => {
        :dns_hostname_assignment => [
          :dns_hostname,
          { :server => :cluster }
        ]
      },
			:order => 'name ASC, idx ASC'
		)
	end
	
	def self.find_all_by_provider_account_id(account)
		self.find_all_by_provider_account_id_and_hostname_id(account, nil)
	end

	def self.find_all_by_provider_account_id_and_hostname_id(account, hostname_id = nil)
    account = (account.is_a?(ProviderAccount) ? account.id : account)
    conditions = {
      :provider_accounts => { :id => account }
    }.merge!( (hostname_id.nil? ? {} : { :dns_hostnames => { :id => hostname_id }}) )

		self.all(
			:select => 'dns_leases.*, dns_hostnames.name as name',
			:conditions => conditions,
			:joins => {
        :dns_hostname_assignment => [
          :dns_hostname,
          { :server => { :cluster => :provider_account } }
        ]
      },
			:order => 'name ASC, idx ASC'
		)
	end

	def active?
		state == ACTIVE
	end
	
	def inactive?
		state == INACTIVE
	end
	
	def dns_hostname
		self.dns_hostname_assignment.dns_hostname
	end
	
	def hostname_base
		dns_hostname.name rescue 'missing'
	end
	
	def hostname
		sprintf("%s-%05d", hostname_base, self.idx)
	end
	
	def servername
		server_name = server.name rescue 'Unknown Server'
		server_name.gsub!(/[^\w\d]+/, '-')
		server_name.downcase
	end
	
	def clustername
		cluster_name = server.cluster.name rescue 'Unknown Cluster'
		cluster_name.gsub!(/[^\w\d]+/, '-')
		cluster_name.downcase
	end
	
	def fqdn
		"#{hostname}.#{servername}.#{clustername}"
	end

	def state
		instance.nil? ? INACTIVE : ACTIVE
	end
	
	def ip
		active? ? instance.private_ip : '256.0.0.0' # use an invalid ip on purpose!
	end
	alias :private_ip :ip
	
	def public_ip
		active? ? instance.public_ip : '256.0.0.0' # use an invalid ip on purpose!
	end
	
	def instance_id
		active? ? instance.instance_id : ''
	end

	def release
		self.dns_hostname_assignment.release self.instance unless inactive? 
	end
		
	def release
		self.dns_hostname_assignment.release self.instance unless inactive?
	end
	
	def acquire instance
		self.dns_hostname_assignment.acquire instance unless active?
	end
	#
    # sort, search and paginate parameters
	#
    def self.per_page
        10
    end
    
    def <=>(hostname)
		self.name <=> hostname.name
    end

    def self.sort_fields
        %w(name)
    end

    def self.search_fields
        %w(name)
    end

end
