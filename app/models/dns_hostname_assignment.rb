
class DnsHostnameAssignment < BaseModel
	belongs_to :dns_hostname
	belongs_to :server
	
	has_many :dns_leases, :dependent => :destroy
	has_many :dns_requests, :dependent => :destroy
	
	validates_presence_of :dns_hostname_id, :server_id
        validates_uniqueness_of :dns_hostname_id, :message => 'This host name is already assigned to another server. Please choose a different host name.'

	attr_accessor :should_destroy
	
	def should_destroy?
		should_destroy.to_i == 1
	end
	
	def self.create(server, hostname)
		if DnsHostname.columns.inject([]) {|a,o| a.push o.name; a }.include? 'provider_account_id'
			pa_id = server.cluster.provider_account_id 
			dns_hostname = DnsHostname.find_or_create_by_name_and_provider_account_id(:name => hostname, :provider_account_id => pa_id)
		else
			dns_hostname = DnsHostname.find_or_create_by_name(:name => hostname)
		end
	end
	
	def self.remove_all_by_server server
		find_all_by_server_id(server).each { |ha| ha.destroy }
	end
	
	def self.remove_all_by_hostname hostname
		find_all_by_dns_hostname_id(hostname).each { |ha| ha.destroy }
	end

	def has_active_leases?
		active_leases.size > 0
	end
	
	def active_leases
		dns_leases.select { |l| l.instance } 
	end
	
	def have_request?(type, instance)
		return false if (type != :acquire || type != :release)
		dns_requests.select { |r| r.request_type == type && r.instance_id == instance.id }.length > 0
	end
	
	def acquire instance
		return if instance.has_dns_lease?(self[:id]) or have_request?(:acquire, instance) 
		dns_requests << DnsRequest.new(:instance_id => instance.id, :request_type => :acquire)
	end
	
	def release instance
		return if not instance.has_dns_lease?(self[:id]) or have_request?(:release, instance)
		dns_requests << DnsRequest.new(:instance_id => instance.id, :request_type => :release)
	end

	def name
		dns_hostname.name
	end
end
