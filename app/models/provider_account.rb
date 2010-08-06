require 'transient_key_store'
require 'tempfile'
require 'digest/md5'
require 'carrot'

class ProviderAccount < BaseModel
	behaviors :service, :associated_attributes

	service_parent_relationship :provider
	service_child_relationship :none
	
	belongs_to :provider
	has_many :instances, :dependent => :destroy
	has_many :server_images, :dependent => :destroy
	has_many :key_pairs, :dependent => :destroy
	has_many :security_groups, :dependent => :destroy
	has_many :firewall_rules, :dependent => :destroy
	has_many :provider_account_parameters, :dependent => :destroy, :order => :position
	has_many :instance_list_readers, :dependent => :destroy, :order => :name
	has_many :out_messages, :dependent => :destroy
	has_many :in_messages, :dependent => :destroy
	has_many :launch_configurations, :dependent => :destroy
	has_many :clusters, :dependent => :destroy
	has_many :publishers, :dependent => :destroy
	has_many :dns_hostnames, :dependent => :destroy
	has_many :zones, :dependent => :destroy, :order => :name
	has_many :auto_scaling_groups, :dependent => :destroy
	has_many :auto_scaling_triggers, :dependent => :destroy
	has_many :load_balancers, :dependent => :destroy
	has_many :reserved_instances, :dependent => :destroy
	
	has_many :cloud_resources, :dependent => :destroy
	has_many :addresses, :class_name => 'CloudAddress', :dependent => :destroy
	has_many :volumes, :class_name => 'CloudVolume', :dependent => :destroy
	has_many :snapshots, :class_name => 'CloudSnapshot', :dependent => :destroy

# iam service
#    has_many :iam_resources, :dependent => :destroy
#    has_many :iam_users, :dependent => :destroy
#    has_many :iam_groups, :dependent => :destroy

	has_and_belongs_to_many :users, :order => :name
	has_and_belongs_to_many :server_profiles, :order => :name
	
	# auditing
	has_many :logs, :class_name => 'AuditLog', :dependent => :nullify
	has_many :audit_logs, :as => :auditable, :dependent => :nullify

	validates_uniqueness_of :name
	validates_presence_of :name, :provider_id, :account_id
	validates_presence_of :aws_access_key_ui, :aws_secret_key_ui, :ssh_master_key_ui
	
	# this will prevent a user from submitting a crafted form to overwrite these attributes directly
	attr_protected :aws_access_key, :aws_secret_key, :ssh_master_key, :messaging_password

	# accessors for the ui part (write-only, reads return empty)
	attr_accessor :destroyed, :aws_access_key_ui, :aws_secret_key_ui, :ssh_master_key_ui

	before_save :strip_spaces_provider_account
	after_update :update_servers
	after_destroy :mark_as_destroyed

	# Generate save_<name_plural>() and <name_singular>_attributes=() methods
	association_attributes :publishers, :instance_list_readers
	association_attributes :server_image, :volumes, :snapshots
  
	include TrackChanges # must follow any before filters

  def messaging_valid?
    begin
      service(:events).first_active_instance.nil?
    rescue ServiceWithoutActiveInstance
      errors.add(:messaging_uri, 'Messaging Service Inactive! No active Events Service instance!')
    rescue NoMethodError
      errors.add(:messaging_uri, 'Events Service does not appear to be created. Please go to Admin Controls -> Services and create an Events service, and provider.')
    else
      unless messaging_can_connect?
        errors.add(:messaging_uri, 'Credentials for connecting to the messaging service appear to be invalid')
      end
    end
    !!(errors.size <= 0)
  end

  def messaging_can_connect?
    uri = URI.parse(messaging_url)
    ssl = !!(uri.scheme == 'amqps')
    connect_options = {
      :host  => uri.host,
      :port  => uri.port,
      :user  => uri.user,
      :pass  => uri.password,
      :vhost => uri.path,
      :ssl   => ssl
    }
    
    begin
      Carrot.new(connect_options).server
    rescue Carrot::AMQP::Server::ServerDown
      Rails.logger.warn "Unable to connect to AMQP service as user '#{messaging_username}'."
      return false
    rescue OpenSSL::SSL::SSLError
      begin
        Rails.logger.warn "Caught SSL Error - retrying with ssl_verify:0"
        Carrot.new(connect_options.merge({:ssl_verify => 0})).server
      rescue Exception => e
        Rails.logger.warn "Caught another exception: #{e.message}"
        return false
      end
    end
    
    true
  end
  
	def messaging_username=(v); end
	def messaging_username(); "nimbul_pa_#{self.id}"; end

	def regenerate_messaging_password
		self.messaging_password = PasswordGenerator.generate
	end
  
  def regenerate_messaging_password!
    self.update_attribute(:messaging_password, PasswordGenerator.generate)
  end
  
	def messaging_url()
    uri = (messaging_uri =~ /^amqps?:\/\// ? messaging_uri : "amqp://#{messaging_uri}")
    uri           = URI.parse(messaging_uri)
    uri.scheme    = (uri.scheme.empty? ? 'amqp' : (uri.scheme.to_sym == :amqps ? 'amqps' : 'amqp'))
    uri.user      = URI.escape(messaging_username)
    uri.password  = URI.escape(messaging_password, '~`!@#$%^&*()_-+=[]{}|\:;<,>.?/')
    uri.path      = (uri.path.empty? ? '/nimbul' : uri.path)
    uri.port      = (uri.port.empty? ? (uri.scheme.to_sym == :amqps ? 5671 : 5672) : uri.port)
    uri.to_s
	end
  
	def mark_as_destroyed
		self.destroyed = true
	end

#    def can_use_more_of?(iam_resource)
#        iam_resource = iam_resource.is_a?(Class) ? iam_resource : iam_resource.class
#        iam_resource = iam_resource.to_s
#        return (self.iam_users.empty? or ( self.iam_users.size < 150 )) if (iam_resource == 'IamUser')
#        return (self.iam_groups.empty? or ( self.iam_groups.size < 150 )) if (iam_resource == 'IamGroup')
#    end

	# interfacing with TransientKeyStore and User Interface
	def aws_access_key_attribute
		"provider_account_#{Digest::MD5.hexdigest(name || 'unknown')}_aws_access_key"
	end

	def aws_access_key_ui=(key)
		key.strip!
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.set(self.aws_access_key_attribute, key) if name and !key.blank?
	end

	def aws_access_key_ui
		return nil if aws_access_key.blank?
		# make sure we have at least 4 characters, grab last 4 and fill the rest with 'x's
		key = ((aws_access_key.rjust(4,'x'))[-4,4]).rjust(16,'x')
		"#{key} - Click to Change"
	end

	def aws_access_key
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.get(self.aws_access_key_attribute) || ''
	end

	def aws_secret_key_attribute
		"provider_account_#{Digest::MD5.hexdigest(name || 'unknown')}_aws_secret_key"
	end

	def aws_secret_key_ui=(key)
		key.strip!
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.set(self.aws_secret_key_attribute, key) if name and !key.blank?
	end

	def aws_secret_key_ui
		return nil if aws_secret_key.blank?
		# make sure we have at least 4 characters, grab last 4 and fill the rest with 'x's
		key = ((aws_secret_key.rjust(4,'x'))[-4,4]).rjust(16,'x')
		"#{key} - Click to Change"
	end

	def aws_secret_key
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.get(self.aws_secret_key_attribute) || ''
	end

	def ssh_master_key_attribute
		"provider_account_#{Digest::MD5.hexdigest(name || 'unknown')}_ssh_master_key"
	end

	def ssh_master_key_ui=(key)
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.set(self.ssh_master_key_attribute, key) if name
	end

	def ssh_master_key_ui
		return nil if ssh_master_key.blank?
		key = ssh_master_key
		# find trailing meaningful characters of the key, make sure we have at least 6 of them, grab last 6 and fill the rest with 'x's
		key = key + '=' unless key.include?('=')
		key = /(.*=)/.match(key)[0]
		key = ((key.rjust(6,'x'))[-6,6]).rjust(16,'x')
		"#{key} - Click to Change"
	end

	def ssh_master_key
		TransientKeyStore.instance(ENV['RAILS_ENV']).reload.get(self.ssh_master_key_attribute) || ''
	end

	def with_ssh_master_key(&block)
		return false if ssh_master_key.blank?
		return false if not block_given?
		
		f = Tempfile.new('.tmp-io-')
		begin
			f.write(ssh_master_key)
			f.flush
			yield(f.path)
		ensure
			f.close!
		end
		
		true
	end

  def send_control_update type, args = {}
    begin
      unless (instance = service(:events).first_active_instance).nil?
        type = "operations/rabbit_mq/#{type.to_s}".classify
        options = { :args => args.merge({ :provider_account_id => self.id }) }
        puts "Creating Operation '#{type}' with arguments: #{options.inspect}"
        instance.operations << Operation.factory(type, options)
      end        
    rescue ServiceWithoutActiveInstance
      # pass if no active instances
    rescue Exception => e
      Rails.logger.warn "Exception Caught: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
      puts "Exception Caught: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    end
  end
  
	attr_accessor :should_destroy
	def should_destroy?
		should_destroy.to_i == 1
	end

  attr_accessor :publishing_to_url

  def publishing_to_url
    if self.s3_bucket.blank? or self.s3_object.blank?
      ""
    else
      "http://#{self.s3_bucket}.s3.amazonaws.com/#{self.s3_object}"
    end
  end

  def to_xml(options = {})
    default_only = [:id, :name, :description, :refresh_at, :refreshed_at, :created_at, :updated_at]
    options[:only] = (options[:only] || []) + default_only
    super(options)
  end

  def to_json(options = {})        
    default_only = [:id, :name, :description, :refresh_at, :refreshed_at, :created_at, :updated_at]
    extra_fields = [:aws_access_key_ui, :aws_secret_key_ui, :ssh_master_key_ui]
    options[:only] = (options[:only] || []) + default_only
    options[:methods] = (options[:methods] || []) + extra_fields
    super(options)
  end

  def save_provider_account_parameters
    provider_account_parameters.each do |i|
      if i.should_destroy?
        i.destroy
      else
        i.save(false)
      end
    end
  end

  def provider_account_parameter_attributes=(provider_account_parameter_attributes)
    provider_account_parameter_attributes.each do |attributes|
      if attributes[:id].blank?
        provider_account_parameters.build(attributes)
      else
        provider_account_parameter = provider_account_parameters.detect { |c| c.id == attributes[:id].to_i }
        provider_account_parameter.attributes = attributes
      end
    end
  end

  def set_provider_account_parameter(name, value, readonly = nil)
    parameter = provider_account_parameters.detect { |p| p.name == name }
    if parameter
      parameter.update_attribute( :value, value )
      parameter.update_attribute( :is_readonly, readonly ) unless readonly.nil?
    else
      parameter = provider_account_parameters.build({
        :name => name,
        :value => value,
        :is_readonly => readonly.nil? ? false : true
      })
    end
    parameter.save
  end

  def get_provider_account_parameter(name)
    parameter = provider_account_parameters.detect { |p| p.name == name }
    return nil if parameter.nil?
    return parameter.value
  end

  def save_launch_configurations
    launch_configurations.each do |i|
      if i.should_destroy?
        i.destroy
      else
        i.save(false)
      end
    end
  end

  def save_auto_scaling_groups
    auto_scaling_groups.each do |i|
      if i.should_destroy?
        i.destroy
      else
        i.save(false)
      end
    end
  end

  def update_servers
    if self.auto_lock_instances
      Server.update_all( ['is_locked=?', 1], { :cluster_id => self.clusters.collect{ |c| c.id } } )
    end
    unless self.default_main_key.blank?
      Server.update_all( ['key_name=?', self.default_main_key], { :cluster_id => self.clusters.collect{ |c| c.id } } )
    end
  end

	# this method is used by find_all_by_user, count_all_by_user and search_by_user in the searchable behavior
	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]

		conditions = ['1=0']
		if user.has_role?("admin")
			conditions = []
		else
			local_conditions = ['1=0']
			unless user.provider_accounts.empty?
				local_conditions << table_name()+".id IN (#{user.provider_accounts.collect{|a| a.id}.join(',')})"
			end
			conditions[0] = "(#{local_conditions.join(' OR ')})"
		end
		
		unless extra_joins.blank?
		    joins = [ '' ] if joins.nil?
		    extra_joins = [ extra_joins ] if not extra_joins.is_a? Array
		    joins = joins + extra_joins
		end

	    unless extra_conditions.blank?
			conditions = [ '' ] if conditions.nil?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' unless conditions[0].blank?
		    conditions[0] << extra_conditions[0]
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

	def self.find_by_security_groups(security_groups = [])
		provider_account_id = security_groups.inject([]) do |a,sg|
			a |= [ sg.provider_account_id ]
		end
		find(provider_account_ids)
	end

	# sort, search and paginate parameters
	def self.per_page
		10
	end

	def self.sort_fields
		%w(name description external_id last_published refreshed_at created_at)
	end

	def self.search_fields
		%w(name description external_id)
	end

	# publish
	def publish
		ProviderAccount::PublisherController.publish_instance_list(self)
		publish_attr = {
			:last_published => Time.now,
			:publish_at => (Time.now + publish_every.seconds),
		}
		update_attributes(publish_attr)
	end

	# refresh
	def refresh(resources = nil)
		Ec2Adapter.refresh_account(self, resources)
		AsAdapter.refresh_account(self, resources)
		StatsAdapter.refresh_account(self) if resources.nil?
  
		now = Time.now
		refresh_attr = {
			:refreshed_at => now,
			:refresh_at => (now + 10.seconds),
		}
		update_attributes(refresh_attr)
	end

	# Factory to create instances of subclasses
	def self.factory(type,params)
		type ||= 'ProviderAccount'
		class_name = type
		if defined? class_name.constantize
			return class_name.constantize.new(params)
		else
			ProviderAccount.new(params)
		end
	end

	def strip_spaces_provider_account
		account_id.strip!
	end

	# getter and setter for the type
	def class_type=(value)
		self[:type] = value
	end

	def class_type
		return self[:type]
	end
end
