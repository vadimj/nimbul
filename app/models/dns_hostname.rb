
class DnsHostname < BaseModel

	VALID_HOSTNAME_REGEX = /^[a-z][a-z0-9-]+[0-9a-z]$/i
	belongs_to :provider_account
	
	has_and_belongs_to_many :servers, :join_table => :dns_hostname_assignments, :select => 'servers.*'
	has_many :dns_hostname_assignments, :dependent => :destroy

	validates_presence_of	:name
	validates_format_of	:name, :with => VALID_HOSTNAME_REGEX, :message => "must begin with a letter, and use only alpha-numeric and dash characters"
#	validates_columns :name

	def self.find_all_by_server_id(server, search, page, extra_joins, extra_conditions, sort = nil)
		conditions = [ 's1.id = ? AND c1.provider_account_id = dns_hostnames.provider_account_id ', (server.is_a?(Server) ? server.id : server) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
		
		joins = [
			'INNER JOIN dns_hostname_assignments AS dha1 ON dns_hostnames.id = dha1.dns_hostname_id',
			'INNER JOIN servers AS s1 ON dha1.server_id = s1.id',
			'INNER JOIN clusters AS c1 ON s1.cluster_id = c1.id',
		]
		joins = joins + extra_joins unless extra_joins.blank?
		
		self.search(search, page, joins, conditions, sort)
	end
	
	def self.find_all_by_cluster_id(cluster, search, page, extra_joins, extra_conditions, sort = nil)
		conditions = [ 'c1.id = ? AND c1.provider_account_id = dns_hostnames.provider_account_id ', (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
		end
		
		joins = [
			'INNER JOIN dns_hostname_assignments AS dha1 ON dns_hostnames.id = dha1.dns_hostname_id',
			'INNER JOIN servers AS s1 ON dha1.server_id = s1.id',
			'INNER JOIN clusters AS c1 ON s1.cluster_id = c1.id',
		]
		joins = joins + extra_joins unless extra_joins.blank?

		self.search(search, page, joins, conditions, sort)
	end
	
	def assign instance
		DnsHostnameAssignment.find_by_server_id_and_dns_hostname_id(instance.server, self).acquire instance
	end

	def accrued_leases(model = nil, only_in_use = false)
		leases = case model.class.name.to_s
			when 'Server':
				DnsLease.find_all_by_server_id_and_hostname_id(model.id, self[:id])
			when 'Cluster':
				DnsLease.find_all_by_cluster_id_and_hostname_id(model.id, self[:id])
			else
				DnsLease.find_all_by_hostname_id(self[:id])
		end
		
		leases = leases.select { |l| l.instance } if only_in_use
		leases
	end

	def has_accrued_leases?(model = nil)
		accrued_leases(model).size > 0
	end
	
	def active_leases(model = nil)
		accrued_leases(model, true)
	end
	
	def has_active_leases?(model = nil)
		active_leases(model).size  > 0
	end
	
	#
    # sort, search and paginate parameters
	#
    def self.per_page
		# XXX: set this to a reasonable size when we figured out how to fix the
		# problem with pagination. (see comment in dns_hostnames/_list.erb)
        1000000 
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
