require 'AWS/AS'
require 'AWS/ELB'
require 'base64'
require 'pp'

class AsAdapter
	cattr_accessor :launch_configuration_name_regex, :launch_configuration_name_message
	
	self.launch_configuration_name_regex = /\A\w[\w\.\-_]+\z/ # alphanumeric
	self.launch_configuration_name_message = "use only letters, numbers, and .-_ please.".freeze
#	self.launch_configuration_name_regex = /\A\w[\w\.\-_@]+\z/ # ASCII, strict
#	self.launch_configuration_name_message = "use only letters, numbers, and .-_@ please.".freeze
	
#  self.login_regex       = /\A\w[\w\.\-_@]+\z/                     # ASCII, strict
  # self.login_regex       = /\A[[:alnum:]][[:alnum:]\.\-_@]+\z/     # Unicode, strict
  # self.login_regex       = /\A[^[:cntrl:]\\<>\/&]*\z/              # Unicode, permissive

#  self.bad_login_message = "use only letters, numbers, and .-_@ please.".freeze

#  self.name_regex        = /\A[^[:cntrl:]\\<>\/&]*\z/              # Unicode, permissive
#  self.bad_name_message  = "avoid non-printing characters and \\&gt;&lt;&amp;/ please.".freeze

#  self.email_name_regex  = '[\w\.%\+\-]+'.freeze
#  self.domain_head_regex = '(?:[A-Z0-9\-]+\.)+'.freeze
#  self.domain_tld_regex  = '(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'.freeze
#  self.email_regex       = /\A#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}\z/i
#  self.bad_email_message = "should look like an email address.".freeze
	
    def self.get_as(account)
        return if account.nil?
        return if account.aws_access_key.blank? or account.aws_secret_key.blank?
        keys = [ account.aws_access_key, account.aws_secret_key ]
        AWS::AS.new(*keys)
    end

    def self.get_elb(account)
        return if account.nil?
        return if account.aws_access_key.blank? or account.aws_secret_key.blank?
        keys = [ account.aws_access_key, account.aws_secret_key ]
        AWS::ELB.new(*keys)
    end

    def self.refresh_account(account, resources = nil)
        if get_as(account).nil?
            Rails.logger.error "Account [#{account.id} - #{account.name}] failed to refresh - unable to load AWS::AS object using account credentials."
            return
        end
      
        if resources.nil? or resources == 'load_balancers'
          begin
            refresh_load_balancers(account)
          rescue Exception => e
            Rails.logger.error "#{e.class.name}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          end
          
        end
        if resources.nil? or resources == 'launch_configurations' or resources == 'auto_scaling_groups'
          begin
            refresh_launch_configurations(account)
          rescue Exception => e
            Rails.logger.error "#{e.class.name}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          end
        end

        if resources.nil? or resources == 'auto_scaling_groups' or resources == 'auto_scaling_triggers'
          begin
            refresh_auto_scaling_groups(account)
          rescue Exception => e
            Rails.logger.error "#{e.class.name}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
          end
        end
    end

    def self.create_launch_configuration(c)
    	as = get_as(c.provider_account)
        options = Hash.new
        c.attributes.each{ |a, value| options[a.to_sym] = value }
    	options[:security_groups] = c.security_groups.collect{ |g| g.name }
        options[:block_device_mappings] = c.block_device_mappings.collect{ |m| { :virtual_name => m.virtual_name, :device_name => m.device_name } }
    	
    	# make sure we generate user_data if this LC is related to a Server
    	unless c.server_id.nil?
            server = Server.find(c.server_id)
            if server
                compress_user_data = true
                options[:user_data] = Server::UserDataController.generate(server, compress_user_data)
            end
    	end
    	
    	begin
            as.create_launch_configuration(options)
            return true
    	rescue
            c.status_message = "#{$!}"
    	end		
        return false
    end
    
    def self.delete_launch_configuration(c)
    	as = get_as(c.provider_account)
    	begin
            as.delete_launch_configuration({ :launch_configuration_name => c.launch_configuration_name})
            return true
    	rescue
            c.status_message = "#{$!}"
    	end		
        return false
    end
    
    def self.refresh_launch_configurations(account)
        as = get_as(account)
        parsers = as.describe_launch_configurations({})

        parsers.each do |parser|
            config = parse_launch_configuration_info(account, parser)
            config.state = :active
            config.save
        end
        account.launch_configurations.each do |i|
            i.state = :disabled unless parsers.detect{ |p| p.launch_configuration_name == i.launch_configuration_name }
        end
        account.save_launch_configurations
    end

    def self.create_auto_scaling_group(g)
    	as = get_as(g.provider_account)
        options = Hash.new
        g.attributes.each{ |a, value| options[a.to_sym] = value }
        options[:auto_scaling_group_name] = g.name
    	options[:launch_configuration_name] = g.launch_configuration.launch_configuration_name
    	options[:availability_zones] = g.zones.collect{ |z| z.name }
    	begin
		as.create_auto_scaling_group(options)
		return true
    	rescue
	    	g.status_message = "#{$!}"
    	end		
	return false
    end

    def self.update_auto_scaling_group(g)
    	as = get_as(g.provider_account)
        options = Hash.new
        g.attributes.each{ |a, value| options[a.to_sym] = value }
        options[:auto_scaling_group_name] = g.name
    	options[:launch_configuration_name] = g.launch_configuration.launch_configuration_name
    	options[:availability_zones] = g.zones.collect{ |z| z.name }
		as.update_auto_scaling_group(options)
		as.create_desired_capacity(options)
		return true
    end

    def self.disable_auto_scaling_group(g)
    	as = get_as(g.provider_account)
    	options = {
            :auto_scaling_group_name => g.name,
            :min_size => 0,
            :max_size => 0,
        }
        as.update_auto_scaling_group(options)
        return true
    end
    
    def self.delete_auto_scaling_group(g)
    	as = get_as(g.provider_account)
        as.delete_auto_scaling_group({ :auto_scaling_group_name => g.name })
		return true
    end
    
    def self.refresh_auto_scaling_groups(account)
        as = get_as(account)
        parsers = as.describe_auto_scaling_groups({})

        parsers.each do |parser|
            group = parse_auto_scaling_group_info(account, parser)
            group.save
            refresh_auto_scaling_triggers(account, group) if group.active?
        end

        account.auto_scaling_groups.each do |i|
            i.state = :disabled unless parsers.detect{ |p| p.auto_scaling_group_name == i.name }
        end
        account.save_auto_scaling_groups
    end

	def self.create_update_auto_scaling_trigger(ast)
		as = get_as(ast.auto_scaling_group.provider_account)
        options = Hash.new
        ast.attributes.each{ |a,value| options[a.to_sym] = value }
        
        options[:trigger_name] = ast.name
        options[:auto_scaling_group_name] = ast.auto_scaling_group.name
        options[:dimensions] = [
			{
				:name => 'AutoScalingGroupName',
				:value => ast.auto_scaling_group.name,
			}
		]
        options[:namespace] = 'AWS/EC2'
        
		as.create_trigger(options)
		return true
	end

	def self.delete_auto_scaling_trigger(ast)
		as = get_as(ast.auto_scaling_group.provider_account)

        options = Hash.new
        options[:trigger_name] = ast.name
        options[:auto_scaling_group_name] = ast.auto_scaling_group.name
        
		as.delete_trigger(options)
		return true
	end

    def self.refresh_auto_scaling_triggers(account, auto_scaling_group)
        as = get_as(account)
        parsers = as.describe_triggers({:auto_scaling_group_name => auto_scaling_group.name})

        parsers.each do |parser|
            trigger = parse_auto_scaling_trigger_info(auto_scaling_group, parser)
            trigger.save
        end
    end

    def self.refresh_load_balancers(account)
        elb = get_elb(account)
        parsers = elb.describe_load_balancers({})

        parsers.each do |parser|
            balancer = parse_load_balancer_info(account, parser)
            balancer.save
        end
    end

    private
    
    def self.parse_launch_configuration_info(account, parser)
        launch_configuration = account.launch_configurations.detect{ |s| s.launch_configuration_name == parser.launch_configuration_name }

        # convert parser object into hash
        attributes = parser.to_hash

	    user_data = attributes['user_data']
	    attributes.delete('user_data')

    	groups = attributes['security_groups'] || []
	    attributes.delete('security_groups')

    	volumes = attributes['block_device_mappings'] || []
	    attributes.delete('block_device_mappings')
	    
	    server_image = account.server_images.detect{ |s| s.image_id == attributes['image_id'] }
	    attributes['server_image_id'] = server_image.id unless server_image.nil?
	    
        if launch_configuration.nil?
            attributes[:name] = attributes['launch_configuration_name']
            launch_configuration = account.launch_configurations.build(attributes)
        else
            launch_configuration.attributes = attributes
        end
        
        # known issue with AS Launch Configurations - user_data is base64 encoded
        launch_configuration.user_data = Base64.decode64(user_data) unless user_data.nil?

        # get security groups
        security_groups = (SecurityGroup.find_all_by_provider_account_id_and_name(account.id, groups))
        launch_configuration.security_groups = ( security_groups || [] )

	    # get volumes
	    volumes.each do |v|
            v_attr = v.to_hash
		    mapping = launch_configuration.block_device_mappings.detect{ |m| m.virtual_name == v_attr['virtual_name'] }
		    if mapping.nil?
			    mapping = launch_configuration.block_device_mappings.build(v_attr)
		    else
			    mapping.attributes = v_attr
		    end
	    end
		
        return launch_configuration
    end

    def self.parse_auto_scaling_group_info(account, parser)
        # convert parser object into hash
        attributes = parser.to_hash

        # name
        attributes[:name] = attributes['auto_scaling_group_name']
        attributes.delete('auto_scaling_group_name')

        # launch configuration
        launch_configuration_name = attributes['launch_configuration_name']
        attributes.delete('launch_configuration_name')
        launch_configuration = (LaunchConfiguration.find_by_provider_account_id_and_launch_configuration_name(account.id, launch_configuration_name, :include => :server))
		server = launch_configuration.nil? ? nil : launch_configuration.server 
        
        # zones
    	zone_names = attributes['availability_zones'] || []
        attributes.delete('availability_zones')
        zones = (Zone.find_all_by_provider_account_id_and_name(account.id, zone_names))

        # balancers
    	balancer_names = attributes['load_balancer_names'] || []
        attributes.delete('load_balancer_names')
        load_balancers = (LoadBalancer.find_all_by_provider_account_id_and_load_balancer_name(account.id, balancer_names))

        # instances
        instance_parsers = attributes['instances'] || []
        attributes.delete('instances')
        instances = []
	    instance_parsers.each do |i|
			# TODO implement better transition here
			h = {}
			i.to_hash.each do |key,value|
				h[key.to_sym] = value
			end
			instance = Ec2Adapter.parse_instance_info(account, {}, h)
			unless server.nil?
				instance.server_id = server.id
				instance.server_name = server.name
			end
			instance.save
			instances << instance
	    end
	    
        auto_scaling_group = account.auto_scaling_groups.detect{ |s| s.name == parser.auto_scaling_group_name }
        if auto_scaling_group.nil?
            auto_scaling_group = account.auto_scaling_groups.build(attributes)
            auto_scaling_group.state = :active
        elsif auto_scaling_group.disabling?
            # if the group exists and is in disabling state - check to see if there are any instances
            # if there are none - remove the group
            auto_scaling_group.remove! if (instances.nil? or instances.size == 0)
        else
            auto_scaling_group.attributes = attributes
            auto_scaling_group.state = :active
        end

        auto_scaling_group.launch_configuration_id = launch_configuration.id
        auto_scaling_group.zones = ( zones || [] )
        auto_scaling_group.load_balancers = ( load_balancers || [] )
        auto_scaling_group.instances = ( instances || [] )
        
        return auto_scaling_group
    end

    def self.parse_auto_scaling_trigger_info(auto_scaling_group, parser)
        # convert parser object into hash
        attributes = parser.to_hash
        
        # TODO - process dimensions
        attributes.delete('dimensions')

		# trigger name
        attributes[:name] = attributes['trigger_name']
        attributes.delete('trigger_name')

		# delete extra attribute
        attributes.delete('auto_scaling_group_name')

        auto_scaling_trigger = auto_scaling_group.auto_scaling_triggers.detect{ |s| s.name == parser.trigger_name }
        if auto_scaling_trigger.nil?
            auto_scaling_trigger = auto_scaling_group.auto_scaling_triggers.build(attributes)
        else
            auto_scaling_trigger.attributes = attributes
        end

        return auto_scaling_trigger
    end
    
    def self.parse_load_balancer_info(account, parser)
        load_balancer = account.load_balancers.detect{ |s| s.load_balancer_name == parser.load_balancer_name }

        # convert parser object into hash
        attributes = parser.to_hash

    	zone_names = attributes['availability_zones'] || []
		attributes.delete('availability_zones')

    	listener_parsers = attributes['listeners'] || []
		attributes.delete('listeners')

        # TODO we don't import health checks yet
        health_check_parser = attributes['health_check']
        attributes.delete('health_check')

        if load_balancer.nil?
            load_balancer = account.load_balancers.build(attributes)
        else
            load_balancer.attributes = attributes
        end

        # get zones
        zones = (Zone.find_all_by_provider_account_id_and_name(account.id, zone_names))
        load_balancer.zones = ( zones || [] )

        # get listeners
        listener_parsers.each do |l|
            l = l.to_hash
            listener = nil
            listener = LoadBalancerListener.find_by_load_balancer_id_and_load_balancer_port_and_instance_port_and_protocol(load_balancer.id, l['load_balancer_port'].to_i, l['instance_port'].to_i, l['protocol']) unless load_balancer.id.nil?
            listener = load_balancer.load_balancer_listeners.build(l) if listener.nil?
        end

        return load_balancer
    end
    
end
