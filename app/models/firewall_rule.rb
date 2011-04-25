class FirewallRule < BaseModel
	belongs_to :provider_account
	has_and_belongs_to_many :security_groups
	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :provider_account_id
	validate :ip_or_group?
    validates_uniqueness_of :ip_range, :scope => [ :provider_account_id, :protocol, :from_port, :to_port ],
		:if => :should_validate_ip_range?,
        :message => "There is already a Firewall Rule for this combination of IP Range, Protocol and Ports"
    validates_uniqueness_of :group_name, :scope => [ :provider_account_id, :group_user_id ],
		:if => :should_validate_group?,
        :message => "There is already a Firewall Rule for this EC2 User ID and Group"
    validates_format_of :ip_range,
		:with => /\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\/(?:3[0-2]|(?:2[0-9]|1\d|[0-9])?)\z/,
		:if => :should_validate_ip_range?,
        :message => "IP Range should be in a form of X.X.X.X/X, e.g. 192.168.50.44/32"
	validates_inclusion_of :protocol, :in => %w( tcp udp icmp ),
		:if => :should_validate_ip_range?,
		:message => "{{value}} is not one of TCP, UDP or ICMP"
    validates_numericality_of :from_port,
		:only_integer => true,
		:greater_than_or_equal_to => 0,
		:less_than_or_equal_to => 65535,
		:if => :should_validate_tcp_udp_range?,
		:message => 'for TCP/UDP, should be an integer 0-65535'
    validates_numericality_of :from_port,
		:only_integer => true,
		:equal_to => -1,
		:if => :should_validate_icmp_range?,
		:message => 'for ICMP, should be set to -1'
	validates_numericality_of :to_port,
		:only_integer => true,
		:greater_than_or_equal_to => 0,
		:less_than_or_equal_to => 65535,
		:if => :should_validate_tcp_udp_range?,
		:message => 'for TCP/UDP, should be an integer 0-65535'
    validates_numericality_of :to_port,
		:only_integer => true,
		:equal_to => -1,
		:if => :should_validate_icmp_range?,
		:message => 'for ICMP, should be set to -1'
	validate :from_port_to_port_correct?, :if => :should_validate_ip_range?		

	include TrackChanges # must follow any before filters

    def description
		if self.ip_range.blank?
			"in group #{group_name} of account #{group_user_id}"
		else
			"in #{ip_range} network connecting over #{protocol.upcase}"
		end
    end

	def should_validate_ip_range?
        !ip_range.blank? or !protocol.blank? or !from_port.blank? or !to_port.blank?
	end

    def should_validate_tcp_udp_range?
		should_validate_ip_range? && (protocol =~ /\A(?:tcp|udp)\z/ )
    end
    
    def should_validate_icmp_range?
		should_validate_ip_range? && (protocol =~ /\Aicmp\z/ )
    end

    def should_validate_group?
        !group_user_id.blank? or !group_name.blank?
    end
    
    def ip_or_group?
		if ip_range.blank? and group_user_id.blank?
			self.errors.add(:ip_range, "You need to specify either IP Range/Protocol/Ports or EC2 User ID/Group Name")
		end
		if should_validate_ip_range? and should_validate_group?
			self.errors.add(:ip_range, "You need to specify either IP based parameters or Group based parameters but not both sets")
		end
    end
    
    def from_port_to_port_correct?
		if !from_port.blank? and !to_port.blank?
			begin
				unless from_port.to_i <= to_port.to_i
					self.errors.add(:from_port, "should be less or equal to 'To' port")
				end
			end
		end
    end

    attr_accessor :should_destroy, :status_message

    def should_destroy?
        should_destroy.to_i == 1
    end

    def enable!
        update_attribute(:is_enabled, true)
    end

    def disable!
        update_attribute(:is_enabled, false)
    end

    # virtual setter for processing group information
    def groups=(groups)
        groups.each do |g|
            self.group_user_id = g[:user_id]
            self.group_name = g[:name]
        end
    end

    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name type protocol from_port to_port ip_range group_user_id group_name)
    end

    def self.search_fields
        %w(name type protocol from_port to_port ip_range group_user_id group_name)
    end

    def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

        conditions = [ 'provider_account_id = ?', (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    self.search(search, page, joins, conditions, sort, filter, include)
    end
end
