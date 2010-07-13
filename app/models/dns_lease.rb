
class DnsLease < BaseModel

	ACTIVE   = 'isup'
	INACTIVE = 'isdown'
	
	belongs_to :instance
	belongs_to :dns_hostname_assignment
	
	validates_presence_of :dns_hostname_assignment_id, :idx
	validates_numericality_of :instance_id, :allow_nil => true

	def self.find_available(assignment)
		# get an unassigned lease with the lowest index that matches the given dns hostname assignment id
		find(
			:first,
			:conditions => [ 'dns_hostname_assignment_id = ? AND instance_id IS NULL', assignment.id ],
			:order => 'idx ASC'
		)
	end
	
	def self.find_all_by_hostname_id(hostname = nil)
		self.find(
			:all,
			:select => 'DISTINCT(dns_leases.id), dns_leases.*, dh.name as name',
			:conditions => [ 'dh.id = ?', (hostname.is_a?(DnsHostname) ? hostname.id : hostname) ],
			:joins => [
				'INNER JOIN dns_hostname_assignments as dha on dns_leases.dns_hostname_assignment_id = dha.id',
				'INNER JOIN dns_hostnames AS dh ON dha.dns_hostname_id = dh.id',
			],
			:order => 'name ASC, idx ASC'
		)
	end

	def self.find_all_by_instance_id(instance)
		self.find_all_by_instance_id_and_hostname_id(instance, nil)
	end
	
	def self.find_all_by_instance_id_and_hostname_id(instance, hostname_id = nil)
		self.find(
			:all,
			:select => 'DISTINCT(dns_leases.id), dns_leases.*, dh.name as name',
			:conditions => if hostname_id.nil?
				[ 'dns_leases.instance_id = ?', (instance.is_a?(Instance) ? instance.id : instance) ]
			else
				[ 'dns_leases.instance_id = ? and dh.id = ?', (instance.is_a?(Instance) ? instance.id : instance), hostname_id ]
			end,
			:joins => [
				'INNER JOIN dns_hostname_assignments as dha on dns_leases.dns_hostname_assignment_id = dha.id',
				'INNER JOIN dns_hostnames AS dh ON dha.dns_hostname_id = dh.id',
				'INNER JOIN servers AS s ON dha.server_id = s.id',
				'INNER JOIN instances AS i ON s.id = i.server_id'
			],
			:order => 'name ASC, idx ASC'
		)
	end
	
	def self.find_all_by_server_id(server)
		self.find_all_by_server_id_and_hostname_id(server, nil)
	end
	
	def self.find_all_by_server_id_and_hostname_id(server, hostname_id= nil)
		self.find(
			:all,
			:select => 'dns_leases.*, dh.name as name',
			:conditions => if hostname_id.nil?
				[ 's.id = ?', (server.is_a?(Server) ? server.id : server) ]
			else
				[ 's.id = ? and dh.id = ?', (server.is_a?(Server) ? server.id : server), hostname_id ]
			end,
			:joins => [
				'INNER JOIN dns_hostname_assignments as dha on dns_leases.dns_hostname_assignment_id = dha.id',
				'INNER JOIN dns_hostnames AS dh ON dha.dns_hostname_id = dh.id',
				'INNER JOIN servers AS s ON dha.server_id = s.id',
			],
			:order => 'name ASC, idx ASC'
		)
	end
	
	def self.find_all_by_cluster_id(cluster)
		self.find_all_by_cluster_id_and_hostname_id(cluster, nil)
	end
	
	def self.find_all_by_cluster_id_and_hostname_id(cluster, hostname_id = nil)
		self.find(
			:all,
			:select => 'dns_leases.*, dh.name as name',
			:conditions => if hostname_id.nil?
				[ 'c.id = ?', (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
			else
				[ 'c.id = ? and dh.id = ?', (cluster.is_a?(Cluster) ? cluster.id : cluster), hostname_id ]
			end,
			:joins => [
				'INNER JOIN dns_hostname_assignments as dha on dns_leases.dns_hostname_assignment_id = dha.id',
				'INNER JOIN dns_hostnames AS dh ON dha.dns_hostname_id = dh.id',
				'INNER JOIN servers AS s ON dha.server_id = s.id',
				'INNER JOIN clusters AS c ON s.cluster_id = c.id'
			],
			:order => 'name ASC, idx ASC'
		)
	end
	
	def self.find_all_by_provider_account_id(account)
		self.find_all_by_provider_account_id_and_hostname_id(account, nil)
	end

	def self.find_all_by_provider_account_id_and_hostname_id(account, hostname_id = nil)
		self.find(
			:all,
			:select => 'dns_leases.*, dh.name as name',
			:conditions => if hostname_id.nil?
				[ 'pa.id = ?', (account.is_a?(ProviderAccount) ? account.id : account)]
			else
				[ 'pa.id = ? and dh.id = ?', (account.is_a?(ProviderAccount) ? account.id : account), hostname_id ]
			end,
			:joins => [
				'INNER JOIN dns_hostname_assignments AS dha ON dns_leases.dns_hostname_assignment_id = dha.id',
				'INNER JOIN dns_hostnames AS dh ON dha.dns_hostname_id = dh.id',
				'INNER JOIN servers AS s ON dha.server_id = s.id',
				'INNER JOIN clusters AS c ON s.cluster_id = c.id',
				'INNER JOIN provider_accounts AS pa ON c.provider_account_id = pa.id'
			],
			:order => 'name ASC, idx ASC'
		)
	end

	def active?
		state == ACTIVE
	end
	
	def inactive?
		state == INACTIVE
	end
	
	def server
		self.dns_hostname_assignment.server
	end
	
	def dns_hostname
		self.dns_hostname_assignment.dns_hostname
	end
	
	def hostname_base
		begin
			self.dns_hostname_assignment.dns_hostname.name
		rescue #nothing
		end
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
