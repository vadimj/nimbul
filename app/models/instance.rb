require 'aasm'

class Instance < BaseModel
  include AASM

  self.inheritance_column = :_none_
  belongs_to :provider_account
  belongs_to :zone
  belongs_to :server, :counter_cache => true
  belongs_to :user
  belongs_to :auto_scaling_group

  has_and_belongs_to_many :security_groups

	has_many :operations, :dependent => :destroy

	has_many :dns_leases, :dependent => :nullify
	has_many :dns_requests, :dependent => :destroy
	has_many :dns_hostname_assignments, :foreign_key => :server_id, :primary_key => :server_id
	has_many :dns_hostnames, :through => :dns_leases, :source => :dns_hostname_assignment
	
	has_many :cloud_resources, :dependent => :nullify
	has_many :instance_resources, :dependent => :destroy
	has_many :addresses, :class_name => 'InstanceAddress', :dependent => :destroy
	has_many :volumes, :class_name => 'InstanceVolume', :dependent => :destroy
	
	has_one :resource_bundle, :dependent => :nullify

	# auditing
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

	alias :hostnames :dns_hostname_assignments
	
  attr_accessor :should_destroy
	attr_accessor :console_timestamp
	attr_accessor :console_output

  def should_destroy?
    should_destroy.to_i == 1
  end

  def name
    self.instance_id
  end

	def mountee_class_name
		'instance'
	end
    
    # aasm
	aasm_column :state
	aasm_initial_state :unknown
	aasm_state :unknown
	aasm_state :requested
	aasm_state :pending, :enter => :initiate_start
	aasm_state :running
	aasm_state :rebooting, :enter => :initiate_reboot
	aasm_state :shutting_down, :enter => :initiate_termination
	aasm_state :terminated

	aasm_event :reboot do
		transitions  :from => [ :running ], :to => :rebooting
	end

	aasm_event :stop do
		transitions  :from => [ :requested, :pending, :running, :rebooting, :shutting_down ], :to => :shutting_down
	end

	aasm_event :terminate do
		transitions  :from => [ :requested, :pending, :running, :rebooting, :shutting_down ], :to => :shutting_down
	end

	include TrackChanges # must follow any before filters

	def dns_assignable?() dns_active? and running? and is_ready?; end
	def dns_releasable?() terminating? or dns_inactive?; end

	def dns_active?() !!dns_active; end
	def dns_inactive?() not dns_active?; end

	def ready?() is_ready == true; end
	def enabled?() ready?; end

	def terminating?() self.shutting_down? or self.terminated?; end

	def disabled?() not enabled?; end

	# handle ready state
	def ready!() update_attribute(:is_ready, true); end
	def enabled!() ready!; end

	def disable!() update_attribute(:is_ready, false); end

	# sort, search and paginate parameters
	def self.per_page
		10
	end

	def self.sort_fields
		%w(instance_id zone_id server_name auto_scaling_group_id state launch_time image_id instance_type key_name public_dns dns_name private_dns volume_name is_locked is_ready user_id)
	end

	def self.search_fields
		%w(instance_id server_name state image_id instance_type key_name public_dns dns_name private_dns volume_name)
	end

	def self.filter_fields
		%w(state user_id server_id)
	end

	def initiate_reboot
		if self.is_locked?
			self.errors.add(:is_locked, "Instance '#{self.instance_id}' is locked; unlock to reboot/stop.")
			raise ActiveRecord::Rollback
		else
			begin
				Ec2Adapter.reboot_instance(self)
			rescue
				msg = "Couldn't reboot instance '#{self.instance_id}': #{$!}."
				self.state = msg
				self.errors.add(:state, msg)
				logger.error msg
				raise ActiveRecord::Rollback
			end
		end
	end

	def initiate_termination
		if self.is_locked?
			self.errors.add(:is_locked, "Instance '#{self.instance_id}' is locked; unlock to reboot/stop.")
			raise ActiveRecord::Rollback
		else
			begin
				self.release_dns_leases
				self.release_launch_configuration
				results = Ec2Adapter.terminate_instance(self)
	            results.each do |result|
					result[:state].gsub!('-','_')
	                i = Instance.find_by_provider_account_id_and_instance_id(self.provider_account_id, result[:id])
	                i.update_attribute(:state, result[:state])
	            end
			rescue
				msg = "Couldn't reboot instance '#{self.instance_id}': #{$!}."			
				self.errors.add(:state, msg)
				self.state = msg
				logger.error msg
				raise ActiveRecord::Rollback
			end
		end
	end
	
	def has_dns_lease?(hostname_assignment = nil)
    conditions = { :instance_id => self[:id] }
		unless hostname_assignment.nil?
			return DnsLease.count(
        :conditions => conditions.merge!({
          :dns_hostname_assignment_id => hostname_assignment[:id]
        })
      ) > 0
		else
			return true if DnsLease.count(:conditions => conditions) > 0
		end
		return false
	end

	def unleased_hostnames
		dns_hostname_assignments.inject([])  do |array,object|
			array.push object unless has_dns_lease? object; array
		end
	end
	
	def acquire_dns_leases
		dns_hostname_assignments.each { |ha| ha.acquire self } 
	end
	
	def acquire hostname
		return if not self.running? # don't allow acquisition if not running. releasing is fine however.
		assignments = dns_hostname_assignments.select { |dha| dha.dns_hostname_id == hostname.id }
		assignments.each { |a| a.acquire self } unless assignments.nil?
	end
	
	def release_dns_leases
		dns_hostname_assignments.each { |ha| ha.release self }
	end
	
	def release_launch_configuration
		self.resource_bundle.release! unless self.resource_bundle.nil?
	end

	def release hostname
		leases = DnsLease.find_all_by_instance_id_and_hostname_id(self, hostname)
		leases.each { |a| a.acquire self } unless leases.nil?
	end

	def self.all_for_resources
		find(:all, :conditions =>
			["state = ? AND ((pending_public_ip IS NOT NULL AND pending_public_ip <> '') OR (pending_volume_id IS NOT NULL AND pending_volume_id <> ''))", 'running'])
	end

	def can_use_cloud_resource?(cloud_resource)
		return false if cloud_resource.nil?
		self.provider_account === cloud_resource.provider_account
	end
	
	def can_use_more_of?(instance_resource_type)
		return true if instance_resource_type == 'InstanceVolume'
		return true if (instance_resource_type == 'InstanceAddress' and self.addresses.empty?)
		return false
	end

	def self.find_all_by_parent(parent, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		send("find_all_by_#{ parent.class.to_s.underscore }", parent, search, page, extra_joins, extra_conditions, sort, filter, include)
	end

  def self.find_all_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
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

  def self.find_all_by_security_group(security_group, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
    joins = [
        'INNER JOIN instances_security_groups ON instances_security_groups.instance_id = instances.id',
    ] + [extra_joins].flatten.compact

    conditions = [ 'instances_security_groups.security_group_id = ?', (security_group.is_a?(SecurityGroup) ? security_group.id : security_group) ]
    unless extra_conditions.blank?
      extra_conditions = [ extra_conditions ].flatten
      conditions[0] << ' AND ' + extra_conditions[0];
      conditions << extra_conditions[1..-1]
    end
  
      self.search(search, page, joins, conditions, sort, filter, include)
  end

  def self.find_all_by_cluster(cluster, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
    joins = [
        'INNER JOIN servers ON servers.id = instances.server_id',
    ] + [extra_joins].flatten.compact

    conditions = [ 'servers.cluster_id = ?', (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
    unless extra_conditions.blank?
      extra_conditions = [ extra_conditions ].flatten
      conditions[0] << ' AND ' + extra_conditions[0];
      conditions << extra_conditions[1..-1]
    end
    self.search(search, page, joins, conditions, sort, filter, include)
  end

	def self.find_all_by_server(server, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		joins = [extra_joins].flatten.compact unless extra_joins.blank?

		conditions = [ 'server_id = ?', (server.is_a?(Server) ? server.id : server) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ].flatten
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
	    end
	    self.search(search, page, joins, conditions, sort, filter, include)
	end

	def self.find_all_by_auto_scaling_group(auto_scaling_group, search, page, extra_joins, extra_conditions, sort=nil, filter=nil, include=nil)
		joins = [extra_joins].flatten.compact unless extra_joins.blank?

		conditions = [ table_name()+'.auto_scaling_group_id = ?', (auto_scaling_group.is_a?(AutoScalingGroup) ? auto_scaling_group.id : auto_scaling_group) ]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ].flatten
			conditions[0] << ' AND ' + extra_conditions[0];
			conditions << extra_conditions[1..-1]
	    end
	    search(search, page, joins, conditions, sort, filter, include)
	end

	# this method is used by find_all_by_user, count_all_by_user and search_by_user in the searchable behavior
	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		conditions = ['1=0']
		if user.has_role?("admin")
			joins = []
			conditions = []
		else
			joins = []
			local_conditions = ['1=0']
			unless user.provider_accounts.empty?
				local_conditions << table_name()+".provider_account_id IN (#{user.provider_accounts.collect{|a| a.id}.join(',')})"
			end
			unless user.clusters.empty?
				servers = Server.find_all_by_user(user)
				unless servers.empty?
					local_conditions << table_name()+".server_id IN (#{servers.collect{|c| c.id}.join(',')})"
				end
			end
			conditions[0] = "(#{local_conditions.join(' OR ')})"
		end

		joins = joins + extra_joins unless extra_joins.blank?
    
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
    
		order = table_name()+'.launch_time DESC' if order.blank?

		options.merge!({
			:joins => joins,
			:conditions => conditions,
			:order => order,
		})

		return options        
	end

	def attach!(cloud_resource)
		# TODO we currently don't do anything on the instance side
		return true
	end

	def detach!(cloud_resource)
		# TODO we currently don't do anything on the instance side
		return true
	end
	
  def with_ssh(user = 'root', options = {})
    pp options
    raise ArgumentError, 'block required!' unless block_given?
    unless options[:keyfile]
      provider_account.with_ssh_master_key do |keyfile|
        ssh_session self[:private_dns], user, options { |ssh| return yield }
      end
    else
      ssh_session self[:private_dns], user, options { |ssh| return yield ssh }
    end
  end

  def send_file src_path, dest_path, options = {}
    require 'escape'
    keyfile = options[:keyfile] or raise ArgumentError, "Missing 'keyfile' argument!"

    user = options.delete(:user) || 'root'
    host = options.delete(:host) || self[:private_dns]
    dest_path = "#{user}@#{host}:#{dest_path}"
    %x[ scp -q -i #{keyfile} -o StrictHostKeyChecking=no -o ConnectTimeout=5 #{Escape.shell_command([src_path, dest_path])} 2>&1 ]
  end
  
  def ssh_execute(command, options = {})
    user = options.delete(:user) || 'root'
    result_as_list = options[:result_as_list].nil? ? false : options.delete(:result_as_list)
    
    with_ssh(user, options) do |ssh|
      ssh.exec! command do |ch, stream, data|
        case stream
          when :stdout
            return (result_as_list ? data.split(/\n/) : data)
          when :stderr
            raise StandardError, data
        end
      end
    end
  end

private

  def ssh_session host, user, options = {}
    pp options
    keyfile = options.delete(:keyfile) or raise ArgumentError, "Missing 'keyfile' argument!"
    begin
      require 'net/ssh'
      options = { :keys => [ keyfile ], :paranoid => false }.merge!(options)
      Net::SSH.start(host, user, options) do |session|
        return yield session
      end
    rescue LoadError
      warn 'Net/SSH not available - unable to ssh to remote hosts'
      return false
    end
  end
  
end
