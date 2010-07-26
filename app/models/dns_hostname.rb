
class DnsHostname < BaseModel

	VALID_HOSTNAME_REGEX = /^[a-z][a-z0-9-]+[0-9a-z]$/i
	belongs_to :provider_account

	has_and_belongs_to_many :servers, :join_table => :dns_hostname_assignments, :select => 'servers.*'
	has_many :dns_hostname_assignments, :dependent => :destroy, :include => { :server => :cluster }

	validates_presence_of	:name
	validates_format_of	:name, :with => VALID_HOSTNAME_REGEX, :message => "must begin with a letter, and use only alpha-numeric and dash characters"
#	validates_columns :name

	attr_accessor :leases, :instance_totals

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
	
  def self.hostname_servers(model)
    @host_servers = all(
      :select => %Q(
        dns_hostnames.*,
        servers.id AS server_id,
        servers.name AS server_name,
        COUNT(instances.id) AS lease_count
      ),
      :joins => [
          'INNER JOIN dns_hostname_assignments AS dha ON dha.dns_hostname_id = dns_hostnames.id',
          'INNER JOIN servers ON dha.server_id = servers.id',
          'INNER JOIN clusters ON servers.cluster_id = clusters.id',
          'INNER JOIN provider_accounts ON clusters.provider_account_id = provider_accounts.id',
          'LEFT JOIN dns_leases AS dl ON dha.id = dl.dns_hostname_assignment_id',
          'LEFT JOIN instances  ON dl.instance_id = instances.id'
      ],
      :conditions => { model.class.table_name.to_sym => { :id => model[:id] } },
      :group => 'servers.id',
      :order => 'dns_hostnames.name ASC'
    )
  end

  def self.accrued_lease_counts(model)
    all(
      :select => 'dns_hostnames.id, COUNT(dns_leases.id) AS accrued_leases',
      :joins => [
          'INNER JOIN dns_hostname_assignments AS dha ON dha.dns_hostname_id = dns_hostnames.id',
          'INNER JOIN servers ON dha.server_id = servers.id',
          'INNER JOIN clusters ON servers.cluster_id = clusters.id',
          'INNER JOIN provider_accounts ON clusters.provider_account_id = provider_accounts.id',
          'LEFT JOIN dns_leases ON dha.id = dns_leases.dns_hostname_assignment_id',
      ],
      :conditions => { model.class.table_name.to_sym => { :id => model[:id] } },
      :group => 'dns_hostnames.id'
    )
  end
  
  def self.active_lease_count(model)
    all(
      :select => 'dns_hostnames.id, COUNT(instances.id) AS active_leases',
      :joins => [
          'INNER JOIN dns_hostname_assignments AS dha ON dha.dns_hostname_id = dns_hostnames.id',
          'INNER JOIN servers ON dha.server_id = servers.id',
          'INNER JOIN clusters ON servers.cluster_id = clusters.id',
          'INNER JOIN provider_accounts ON clusters.provider_account_id = provider_accounts.id',
          'LEFT JOIN dns_leases ON dha.id = dns_leases.dns_hostname_assignment_id',
          'LEFT JOIN instances ON dns_leases.instance_id = instances.id'
      ],
      :conditions => { model.class.table_name.to_sym => { :id => model[:id] } },
      :group => 'dns_hostnames.id'
    )
  end

  def self.normalize_hostname hostname, model
    case hostname
      when DnsHostname
        hostname
      when Fixnum
        DnsHostname.find hostname
      when String, Symbol
        hostname = hostname.to_s if hostname.is_a? Symbol
        if hostname =~ /^\d+$/
          DnsHostname.find(Integer(hostname))
        else
          joins = nil
          conditions = { :dns_hostnames => { :name => hostname } }
          unless model.nil?
            conditions.merge!({
              model.class.table_name.to_sym => { :id => model[:id] }
            })
          end
          DnsHostname.first(
            :select => 'dns_hostnames.*',
            :joins => [
                'INNER JOIN dns_hostname_assignments AS dha ON dha.dns_hostname_id = dns_hostnames.id',
                'INNER JOIN servers ON dha.server_id = servers.id',
                'INNER JOIN clusters ON servers.cluster_id = clusters.id',
                'INNER JOIN provider_accounts ON clusters.provider_account_id = provider_accounts.id',
            ],
            :conditions => conditions,
            :group => 'dns_hostnames.id'
          )
        end
    end        
  end
  
  def self.hostname_instances(hostname, model)
    Instance.all(
      :joins => {
        :server => [
          :dns_hostnames,
          { :cluster => :provider_account }
        ]
      },
      :conditions => {
        :dns_hostnames => { :id => normalize_hostname(hostname, model)[:id] },
        model.class.table_name.to_sym => { :id => model[:id] }
      }
    )
  end

  def self.unassigned_hostname_instances(hostname, model)
    DnsLease.all(
      :joins => {
        :server => [
          :dns_hostnames,
          { :cluster => :provider_account }
        ]
      },
      :conditions => {
        :dns_hostnames => { :id => normalize_hostname(hostname, model)[:id] },
        model.class.table_name.to_sym => { :id => model[:id] }
      }
    )
  end
  
  def self.hostname_instance_totals(model)
    all(
      :select => %Q(
        dns_hostnames.*,
        dns_hostnames.id as hostname_id,
        dns_hostnames.name as hostname_name,
        servers.id as server_id,
        servers.name as server_name,
        instances.id as instance_id,
        instances.instance_id as instance_ec2_id,
        clusters.id as cluster_id,
        clusters.name as cluster_name,
        provider_accounts.id as provider_account_id,
        provider_accounts.name as provider_account_name
      ),
      :joins => { :servers => { :instances => { :server => { :cluster => :provider_account } } } },
      :conditions => {
        model.class.table_name.to_sym => { :id => model[:id] },
        :instances => { :dns_active => 1, :is_ready => 1, :state => :running }
      }
    )
  end

  def self.paginated_model_search(model, params = {}, hostname_id = nil)
    params[:sort] = params[:sort].nil? ? 'name' : params[:sort].gsub('dns-hostname', 'name') 
    include = {
      :dns_hostname_assignments => [ { :server => { :cluster => :provider_account } }, :dns_leases ]
    }
    joins = [
      'INNER JOIN dns_hostname_assignments AS dha ON dha.dns_hostname_id = dns_hostnames.id',
      'LEFT JOIN dns_leases AS dl ON dha.id = dl.dns_hostname_assignment_id',
      'INNER JOIN servers AS s ON dha.server_id = s.id',
      'INNER JOIN clusters AS c ON s.cluster_id = c.id',
      'INNER JOIN provider_accounts AS pa ON c.provider_account_id = pa.id',
    ]
    conditions = [''] if conditions.nil? or conditions.empty?
    conditions = [ "#{model.class.table_name}.id = ?", model[:id] ]
    unless hostname_id.nil?
      conditions[0] += ' AND dns_hostnames.id = ?'
      conditions << hostname_id
    end

    hostnames = DnsHostname.search(params[:search], params[:page], joins, conditions, params[:sort], nil, include, 'dns_hostnames.id')

    accrued_leases = DnsHostname.accrued_lease_counts(model)
    active_leases = DnsHostname.active_lease_count(model)
    hostname_instance_totals = DnsHostname.hostname_instance_totals(model)
        
    hostnames.each do |h|
      h.leases ||= { :active => 0, :accrued => 0 }
      h.instance_totals ||= 0
      h.leases[:active]  = Integer((active_leases.select { |l| l[:id] == h[:id] }[0][:active_leases] rescue nil))
      h.leases[:accrued] = Integer((accrued_leases.select { |l| l[:id] == h[:id] }[0][:accrued_leases] rescue nil))
      h.instance_totals  = hostname_instance_totals.select { |l| h[:id] == l[:id] }.count
    end
	end

	def assign instance
		DnsHostnameAssignment.find_by_server_id_and_dns_hostname_id(instance.server, self).acquire instance
	end

	def accrued_leases(model = nil, only_in_use = false)
		case model
			when Server:
				DnsLease.find_all_by_server_id_and_hostname_id(model[:id], self[:id], only_in_use)
			when Cluster:
				DnsLease.find_all_by_cluster_id_and_hostname_id(model[:id], self[:id], only_in_use)
			else
				DnsLease.find_all_by_hostname_id(self[:id], only_in_use)
		end
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
