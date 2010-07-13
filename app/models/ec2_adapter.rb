require 'AWS/EC2'
require 'pp'

class Ec2Adapter
    def self.get_ec2(account)
        return if account.nil?
        return if account.aws_access_key.blank? or account.aws_secret_key.blank?
        keys = [ account.aws_access_key, account.aws_secret_key ]
        AWS::EC2.new(*keys)
    end

    def self.refresh_account(account, resources = nil)
      # don't proceed if we can't get the ec2 account object
      if get_ec2(account).nil?
        Rails.logger.error "Account [#{account.id} - #{account.name}] failed to refresh - unable to load AWS::EC2 object using account credentials."
        return
      end
      
      # always refresh zones
      refresh_zones(account)
      
      # always refresh key pairs
      refresh_key_pairs(account)

      if resources.nil? or resources == 'server_images' 
          refresh_server_images(account)
      end
      if resources.nil? or resources == 'security_groups' or resources == 'instances' 
          refresh_security_groups(account)
      end
      if resources.nil? or resources == 'instances'
          refresh_instances(account)
      end
      if resources.nil? or resources == 'volumes'
          refresh_volumes(account)
      end
      if resources.nil? or resources == 'snapshots'
          refresh_snapshots(account)
      end
      if resources.nil? or resources == 'addresses' 
          refresh_addresses(account)
      end
      if resources.nil? or resources == 'reserved_instances'
          refresh_reserved_instances(account)
      end
    end

    def self.refresh_addresses(account)
        ec2 = get_ec2(account)
        cloud_addresses = ec2.describe_addresses
        account_addresses = CloudAddress.find_all_by_provider_account_id(account.id, :include => :instance_addresses)
        account_instances = Instance.find_all_by_provider_account_id(account.id, :include => :addresses)
		
        account_addresses.each do |a|
            a.should_destroy = 1
        end
        
        cloud_addresses.each do |ca|
			ca[:cloud_id] = ca[:public_ip]
			instance_id = ca[:instance_id]
			ca[:state] = instance_id.blank? ? 'available' : 'in-use'
			ca.delete(:public_ip)
			
			# parse instance info
			instance_id = ca[:instance_id]
			ca.delete(:instance_id)
			instance = nil
			if instance_id.blank?
				ca[:cloud_instance_id] = nil
				ca[:instance_id] = nil
			else
				ca[:cloud_instance_id] = instance_id
				instance = account_instances.detect{ |i| i.instance_id == instance_id }
				ca[:instance_id] = instance.id unless instance.nil?
			end

			# find address in the db (if any) and update / create
            aa = account_addresses.detect{ |a| a.cloud_id == ca[:cloud_id] }
            if aa.nil?
				ca[:name] = ca[:cloud_id]
                aa = account.addresses.build(ca)
            else
                aa.attributes = ca
                aa.should_destroy = 0
            end
   			aa.save
   			
			# update instance resources
			conditions = [ "state != ?", 'pending' ]
			unless instance.nil?
				conditions[0] += " and instance_id != ?"
				conditions << instance.id
				attrs = {
					:cloud_resource_id => aa.id,
					:state => 'attached',
					:mount_type => CloudAddress.default_mount_type,
				}
				i_resource = instance.addresses.detect{ |ir| ir.cloud_resource_id == aa.id }
                if i_resource.nil?
                    i_resource = instance.addresses.build(attrs)
                else
					i_resource.attributes = attrs
				end
                i_resource.save
			end
			aa.instance_addresses.update_all("state = 'detached'", conditions )
        end
        
        account_addresses.each do |aa|
            aa.destroy if aa.should_destroy?
        end
    end

    def self.refresh_volumes(account)
        ec2 = get_ec2(account)
        cloud_volumes = ec2.describe_volumes
        zones = account.zones
        account_volumes = CloudVolume.find_all_by_provider_account_id(account.id, :include => :instance_volumes)
        account_instances = Instance.find_all_by_provider_account_id(account.id, :include => :volumes)
		
        account_volumes.each do |account_volume|
            account_volume.should_destroy = 1
        end
        
        cloud_volumes.each do |cloud_volume|
			# remove attachment set before saving
			attachment_set = cloud_volume[:attachment_set]
			cloud_volume.delete(:attachment_set)

            # parse volume info
            cloud_volume = parse_volume_info(account, cloud_volume, zones)
			account_volume = account_volumes.detect{ |volume| volume.cloud_id == cloud_volume[:cloud_id] }
            if account_volume.nil?
				cloud_volume[:name] = cloud_volume[:cloud_id]
                account_volume = account.volumes.build(cloud_volume)
            else
                account_volume.attributes = cloud_volume
                account_volume.should_destroy = 0
            end
   			account_volume.save
   			
   			# parse attachment set
   			parse_volume_attachment_set(account, account_volume, attachment_set, account_instances)
        end
        
        account_volumes.each do |account_volume|
            account_volume.destroy if account_volume.should_destroy?
        end
    end
    
	def self.parse_volume_info(account, attributes, zones=nil)
		zones ||= account.zones
		
		# parse attributes
		attributes[:cloud_id] = attributes[:volume_id]
		attributes.delete(:volume_id)
		attributes[:parent_cloud_id] = attributes[:snapshot_id]
		attributes.delete(:snapshot_id)
		attributes[:state] = attributes[:status]
		attributes.delete(:status)
		
		# parse zone info
        zone_name = attributes[:availability_zone]
        attributes.delete(:availability_zone)
        zone = zones.detect{ |z| z.name == zone_name }
        attributes[:zone_id] = zone.id unless zone.nil?

		return attributes
	end

	def self.parse_volume_attachment_set(account, account_volume, attachment_set, account_instances=nil)
		account_instances ||= Instance.find_all_by_provider_account_id(account.id, :include => :volumes)
		
		attachment_state = nil
		attach_time = nil
		device = nil
		attached_cloud_instance_id = nil
		attached_instance_id = nil
		attachment_instance_ids = []
		
		# parse attachments one by one
		attachment_set.each do |a_set|
			attachment_state = a_set[:status]
			attach_time = a_set[:attach_time]
			device = a_set[:device]
			
			# find the instance
			cloud_instance_id = a_set[:instance_id]
			instance_id = nil
			instance = account_instances.detect{ |i| i.instance_id == cloud_instance_id }
			instance_id = instance.id unless instance.nil?
			
			# update instance resources
			unless instance.nil?
				attachment_instance_ids << instance_id
				attrs = {
					:cloud_resource_id => account_volume.id,
					:mount_point => device,
					:mount_type => CloudVolume.default_mount_type,
					:state => attachment_state,
				}
				i_resource = instance.volumes.detect{ |ir| ir.cloud_resource_id == account_volume.id }
				if i_resource.nil?
					i_resource = instance.volumes.build(attrs)
				else
					i_resource.attributes = attrs
				end
				i_resource.save
			end
			
			# for the instance that has this volume attached - memorize it's ids
			if attachment_state == 'attached'
				attached_cloud_instance_id = cloud_instance_id
				attached_instance_id = instance_id
			end
		end
			
		# update volume with the last attachment information
		account_volume.update_attributes({
			:cloud_instance_id => attached_cloud_instance_id,
			:instance_id => attached_instance_id,
			:attachment_state => attachment_state,
			:attach_time => attach_time,
		})

		# mark all other other non-pending instance resources as 'detached'
		conditions = [ "state != ?", 'pending' ]
		attachment_instance_ids.each do |instance_id|
			conditions[0] += " and instance_id != ?"
			conditions << instance_id
		end
		account_volume.instance_volumes.update_all("state = 'detached'", conditions )
    end

    def self.create_volume(volume, size_or_snapshot, zone)
		account = volume.provider_account
		ec2 = get_ec2(account)
        zone = zone.is_a?(Zone) ? zone.name : zone
        if size_or_snapshot =~ /snap/
            res = ec2.create_volume_from_snapshot(size_or_snapshot, zone)
        else
            res = ec2.create_volume(size_or_snapshot, zone)
        end
        return parse_volume_info(account, res)
    end

    def self.delete_volume(volume)
        return nil if volume.nil?
        ec2 = get_ec2(volume.provider_account)
        ec2.delete_volume(volume.cloud_id)
    end
    
    def self.refresh_snapshots(account)
        ec2 = get_ec2(account)
        cloud_snapshots = ec2.describe_snapshots
        account_snapshots = account.snapshots
		
        account_snapshots.each do |account_snapshot|
            account_snapshot.should_destroy = 1
        end
        
        cloud_snapshots.each do |cloud_snapshot|
			# parse snapshot info
			cloud_snapshot = parse_snapshot_info(account, cloud_snapshot)
            account_snapshot = account_snapshots.detect{ |snapshot| snapshot.cloud_id == cloud_snapshot[:cloud_id] }
            if account_snapshot.nil?
				cloud_snapshot[:name] = cloud_snapshot[:cloud_id]
                account_snapshot = account.snapshots.build(cloud_snapshot)
            else
                account_snapshot.attributes = cloud_snapshot
                account_snapshot.should_destroy = 0
            end
   			account_snapshot.save
        end
        
        account_snapshots.each do |account_snapshot|
            account_snapshot.destroy if account_snapshot.should_destroy?
        end
    end

    def self.refresh_security_groups(account)
        ec2 = get_ec2(account)
        cloud_groups = ec2.describe_security_groups
        account_groups = SecurityGroup.find_all_by_provider_account_id(account.id, :include => :firewall_rules)
        account_firewall_rules = FirewallRule.find_all_by_provider_account_id(account.id, :include => :security_groups)

        account_groups.each do |account_group|
            account_group.should_destroy = 1
        end

        cloud_groups.each do |group|
            # remove :grants element before building group record
            grants = group[:grants]
            group.delete(:grants)
            
            account_group = account_groups.detect{ |g| g.name == group[:name] }
            if account_group.nil?
                account_group = account.security_groups.build(group)
            else
                account_group.attributes = group
                account_group.should_destroy = 0
		    end
			account_group.save

            # import firewall rules
            grants.each do |grant|
				fr = nil
				
                # process ip-based rule 
                unless grant[:ip_range].blank?
					fr = account_firewall_rules.detect{ |r| r.protocol == grant[:protocol] and r.from_port == grant[:from_port] and r.to_port == grant[:to_port] and r.ip_range == grant[:ip_range]}
                    if fr.nil?
                        fr = account.firewall_rules.build({
                            :protocol => grant[:protocol],
                            :from_port => grant[:from_port],
                            :to_port => grant[:to_port],
                            :ip_range => grant[:ip_range],
                        })
                        fr.name = "Allow access from #{fr.ip_range} to #{fr.protocol} #{fr.from_port}-#{fr.to_port}"
                        fr.save
                    end
                    account_group.firewall_rules << fr unless account_group.firewall_rules.include?(fr)
                    account_firewall_rules << fr if account_firewall_rules.detect{ |r| r.protocol == grant[:protocol] and r.from_port == grant[:from_port] and r.to_port == grant[:to_port] and r.ip_range == grant[:ip_range]}.nil?
                end

                # process group-based rule 
                unless grant[:groups].nil?
                    # analyze all groups
                    grant[:groups].each do |g|
                        grant[:group_user_id] = g[:user_id]
                        grant[:group_name] = g[:name]
       					fr = account_firewall_rules.detect{ |r| r.group_user_id == grant[:group_user_id] and r.group_name == grant[:group_name] }
					    if fr.nil?
                            fr = account.firewall_rules.build({
                                :group_user_id => grant[:group_user_id],
                                :group_name => grant[:group_name],
                            })
                            fr.name = "Allow access from #{fr.group_user_id}/#{fr.group_name}"
                            fr.save
                        end
	                    account_group.firewall_rules << fr unless account_group.firewall_rules.include?(fr)
	                    account_firewall_rules << fr if account_firewall_rules.detect{ |r| r.group_user_id == grant[:group_user_id] and r.group_name == grant[:group_name] }.nil?
                    end
                end
            end
        end
        
        account_groups.each do |account_group|
            account_group.destroy if account_group.should_destroy?
        end
    end

    def self.refresh_zones(account)
        ec2 = get_ec2(account)
        zones = ec2.describe_availability_zones
        account_zones = account.zones
        
        zones.each do |i|
            zone = account_zones.detect{ |s| s.name == i[:name] }
            if zone.nil?
                zone = account.zones.build(i)
            else
                zone.attributes = i
            end
            zone.save
        end
    end

    def self.refresh_key_pairs(account)
        ec2 = get_ec2(account)
        key_pairs = ec2.describe_keypairs
        account_key_pairs = account.key_pairs
        
        key_pairs.each do |i|
            key_pair = account_key_pairs.detect{ |s| s.name == i[:name] }
            if key_pair.nil?
                key_pair = account.key_pairs.build(i)
            else
                key_pair.attributes = i
            end
			key_pair.save
        end
    end

    def self.refresh_server_images(account)
        ec2 = get_ec2(account)
        account_images = ServerImage.find_all_by_provider_account_id(account.id)

		# refresh images imported from other accounts
		# AWS call fails if we try to batch-refresh with any invalid image_ids included
		# so we refresh them one-by-one
		account_images.select{ |i| i.owner_id != account.external_id }.each do |oi|
			refresh_server_image(oi)
		end

		# refresh our images
        opts = { :owners => [ 'self' ]}
       	images = ec2.describe_images(opts)
        cloud_images = ec2.describe_images(opts)

		# presume all our images are unavailable unless we find them at Amazon
        account_images.select{ |i| i.owner_id == account.external_id }.each do |account_image|
            account_image.state = 'unavailable'
        end

        # refresh server images, add new ones if any
        cloud_images.each do |cloud_image|
			# parse image info
			cloud_image = parse_server_image_info(account, cloud_image)
	        account_image = account_images.detect{ |i| i.image_id == cloud_image[:image_id] }
			if account_image.nil?
				# for new server images, set their name to image_id
				cloud_image[:name] = cloud_image[:image_id] if cloud_image[:name].blank?
			    account_image = account.server_images.build(cloud_image)
			else
			    account_image.attributes = cloud_image
			end
   			account_image.save
        end
    end

	def self.refresh_server_image(server_image)
		account = server_image.provider_account
		ec2 = get_ec2(account)
		opts = { :image_ids => [ server_image.image_id ] }
		begin
			images = ec2.describe_images(opts)
			if images.size > 0
				i = images[0]
				# preserve the name
				i[:name] = server_image.name if i[:name].blank?
				server_image.attributes = parse_server_image_info(account, i)
				server_image.save
    	    end
		rescue
			server_image.location = 'This server image is no longer available'
			server_image.state = 'unavailable'
			server_image.save
		end
	end

	def self.parse_server_image_info(account, attributes)
        # delete :id attribute before building a server image record - :id is a special rails attribute
        attributes[:image_id] = attributes[:id]
        attributes.delete(:id)
		return attributes
	end

    def self.refresh_instances(account)
        ec2 = get_ec2(account)
        # refresh instances
        # there is a bug in EC2 library that calls reservations "instances"
        reservations = ec2.describe_instances
        account_instances = account.instances
        account_zones = account.zones
        account_security_groups = account.security_groups
        
        # mark all the instances that are not in 'requested' state as to be destroyed
        # this will be reverted when we find a corresponding instance on the cloud
        account_instances.each do |i|
            i.should_destroy = 1 unless i.requested?
        end
	    
	    reservations.each do |r|
    	    r[:instances].each do |i|
				instance = parse_instance_info(account, r, i, account_instances, account_zones, account_security_groups)
				account_instances.collect{|ai| ai.should_destroy = 0 if ai.id == instance.id}
				instance.save
	    	end
    	end
		
		account_instances.each do |i|
            i.destroy if i.should_destroy?
        end
    end

    def self.refresh_reserved_instances(account)
        ec2 = get_ec2(account)
        account_zones = account.zones

        reserved_instances = ec2.describe_reserved_instances
        reserved_instances.each do |i|
            reserved_instance = account.reserved_instances.detect{ |s| s.reserved_instances_id == i[:reserved_instances_id] }
            zone = account_zones.detect{ |z| z.name == i[:zone] }
            i[:zone_id] = zone.id if zone
            i.delete(:zone)
            if reserved_instance.nil?
                reserved_instance = account.reserved_instances.build(i)
            else
                reserved_instance.attributes = i
            end
            reserved_instance.save
        end
    end

    def self.run_instances(server, count, p)
        cluster = Cluster.find(server.cluster_id, :include => [ :provider_account ])
        account = cluster.provider_account
        ec2 = get_ec2(account)
        
        # if a launch configuration was specified - find it
		rb = server.resource_bundles.detect{ |rb| rb.id == p[:resource_bundle_id] } unless p[:resource_bundle_id].blank?
        
        # default prefix for messages
        msg_prefix = "Ec2Adapter.run_instances: server #{server.name} [#{server.id}]"
        
		# assign parameters
        dns_active = p[:dns_active].nil? ? true : p[:dns_active]
        user_id = p[:user_id] || nil
        image_id = server.image_id

        security_groups = server.security_groups.collect{|g| g.name}
        unless account.default_security_group.blank?
            security_groups << account.default_security_group unless security_groups.include?(account.default_security_group)
        end
        
        key_name = server.key_name
        unless account.default_main_key.blank?
            key_name = account.default_main_key
        end

        compress_user_data = true # false by default
    	options = {
            :key_name => key_name,
            :instance_type => server.type,
            :user_data => Server::UserDataController.generate(server, compress_user_data),
            :security_groups => security_groups,
        }

		instances = []
		0.upto(count-1) do |c|
			# prepare a launch configuration (if any exist for this server)
			rb = nil
			if server.has_resource_bundles?
				# see if a launch configuration has been specified
				rb = server.resource_bundles.detect{ |r| r.id == p[:resource_bundle_id] } unless p[:resource_bundle_id].blank?
				# get a default one if not
				rb = server.next_available_resource_bundle if rb.nil?
				if rb.nil?
					msg = "Not enough launch configurations configured and no default launch configuration for this server. #{c} instances started."
					Rails.logger.error "#{msg_prefix} - #{msg}"
					raise msg
				end
			end
			
	        # if zone is not set - suggest one
	        zone = (rb.nil? or rb.zone_id.blank?) ? find_best_zone(server) : rb.zone
	        options[:zone] = zone.name unless zone.nil?

	        # start the instance
	        # to support auto scaling, the actual mounting of the launch configuration takes place in instance_observer
	        min_count = 1
	        max_count = 1
	        reservation = ec2.run_instances(image_id, min_count, max_count, options)
	        instance = nil
	        reservation[:instances].each do |i|
	            i.merge!({
	                :user_id => user_id,
	                :state => 'requested',
	                :server_id => server.id,
	                :server_name => server.name,
	                :is_locked => account.auto_lock_instances || server.is_locked,
	                :dns_active => dns_active,
	            })
	            
	            # store information about pending launch configuration
	            i.merge!({ :pending_launch_configuration_id => rb.id }) unless rb.nil?

	            instance = parse_instance_info(account, reservation, i)
	            instance.save
	            instances << instance
				Rails.logger.debug "#{msg_prefix} - started instance: #{instance.name} [#{instance.id}]"
			end
		end
		
		return instances
	end

	def self.attach(cloud_resource, instance, mount_point=nil)
		if cloud_resource.is_a?(CloudAddress)
			attach_address(cloud_resource, instance)
		elsif cloud_resource.is_a?(CloudVolume)
			attach_volume(cloud_resource, instance, mount_point)
		else
			raise "Unrecognized cloud resource type: #{cloud_resource.class_type}"
		end
	end
	
	def self.attach_address(address, instance)
		account = address.provider_account
		refresh_addresses(account)
		a = account.addresses.find_by_cloud_id(address.cloud_id)
		raise "address '#{address.cloud_id}' is no longer available" if a.nil?
		raise "address '#{a.cloud_id}' is already attached to #{instance.instance_id}" if a.cloud_instance_id == instance.instance_id
       	ec2 = get_ec2(account)
		ec2.associate_address(instance.instance_id, a.cloud_id)
		return true
	end
	
	def self.attach_volume(volume, instance, mount_point)
		account = volume.provider_account
		refresh_volumes(account)
		v = account.volumes.find_by_cloud_id(volume.cloud_id)
		raise "volume '#{volume.cloud_id}' is no longer available" if v.nil?
		raise "volume '#{v.cloud_id}' is already attached to #{instance.instance_id}" if v.cloud_instance_id == instance.instance_id
       	ec2 = get_ec2(account)
		ec2.attach_volume(v.cloud_id, instance.instance_id, mount_point)
		return true
	end

	def self.detach(cloud_resource, force=false)
		if cloud_resource.is_a?(CloudAddress)
			self.detach_address(cloud_resource, force)
		elsif cloud_resource.is_a?(CloudVolume)
			self.detach_volume(cloud_resource, force)
		else
			raise "Unrecognized cloud resource type: #{cloud_resource.class_type}"
		end
	end
	
	def self.detach_address(address, force=false)
		account = address.provider_account
       	ec2 = get_ec2(account)
		ec2.disassociate_address(address.cloud_id)
		return true
	end
	
	def self.detach_volume(volume, force=false)
		account = volume.provider_account
       	ec2 = get_ec2(account)
		ec2.detach_volume(volume.cloud_id, nil, nil, force)
		return true
	end

	def self.reboot_instance(instance)
		return nil if instance.nil?
		account = instance.provider_account
    	ec2 = get_ec2(account)
		result = ec2.reboot_instances([instance.instance_id])
	end

	def self.terminate_instance(instance)
		return nil if instance.nil?
		account = instance.provider_account
    	ec2 = get_ec2(account)
        # returns {:state=>"shutting-down", :previous_state=>"running", :id=>"i-1392c97a"}
		ec2.terminate_instances([instance.instance_id])
	end

	def self.get_console_output(instance)
		return nil if instance.nil?
		account = instance.provider_account
        ec2 = get_ec2(account)
        out = {}
        begin
    		out = ec2.get_console_output(instance.instance_id)
        rescue
            out[:timestamp] = '<N/A>'
            out[:output] = '<Console output is not available yet, check back later>'
        end
		instance.console_timestamp = out[:timestamp]
		instance.console_output = out[:output].gsub("\n\r","\n")
		return instance
	end

	private

    def self.find_best_zone(server)
        cluster = Cluster.find(server.cluster_id, :include => [ :provider_account ])
        provider_account = cluster.provider_account

        # find zones with reserved instances of this instance type
        zone_names = []
        unless provider_account.reserved_instances.nil?
            zone_names = provider_account.reserved_instances.collect{|i| i.zone if i.instance_type == server.type and i.state == 'active'}.compact.uniq
        end

        # amongst zones find zones with unused reserved instances
        free_zone_names = []
        zone_names.each do |zone_name|
            reserved = ReservedInstance.sum(:count, :conditions => ['provider_account_id=? AND zone=? AND instance_type=? AND state=?', provider_account.id, zone_name, server.type, 'active'])
            running = Instance.count(:all, :conditions => ['provider_account_id=? AND zone=? AND type=? AND (state=? OR state=?)', provider_account.id, zone_name, server.type, 'running', 'pending'])
            free_zone_names << zone_name if reserved > running
        end
        
        # use free zones if they are available
        zone_names = free_zone_names if free_zone_names.size > 0

		# couldn't suggest a zone
		return nil if zone_names.empty?

        # choose a random zone if zones are not empty
		zone_name = zone_names.sort_by{ rand }[0]
		return provider_account.zones.find_by_name(zone_name)
    end

	# also used by AsAdapter to process info about AS Group's instances
	def self.parse_instance_info(account, reservation, attributes, account_instances=nil, account_zones=nil, account_security_groups=nil)
		as_lifecycle_state_to_ec2_state = {}
		as_lifecycle_state_to_ec2_state['Pending'] = 'pending'
		as_lifecycle_state_to_ec2_state['InService'] = 'running'
		as_lifecycle_state_to_ec2_state['Terminating'] = 'shutting-down'
		as_lifecycle_state_to_ec2_state['Terminated'] = 'terminated'

		account_instances ||= account.instances
		account_zones ||= account.zones
		account_security_groups ||= account.security_groups
		
        # process ec2 instance info
        if attributes[:lifecycle_state].blank?
			# delete :id attribute before building a instance record - :id is a special rails attribute
			attributes[:instance_id] = attributes[:id]
	        attributes.delete(:id)
	        zone_name = attributes[:zone]
	        attributes.delete(:zone)
		# process as instance info
		else
			attributes[:state] = as_lifecycle_state_to_ec2_state[attributes[:lifecycle_state]]
			attributes.delete(:lifecycle_state)
			attributes[:state] ||= 'unknown'
	        zone_name = attributes[:availability_zone]
	        attributes.delete(:availability_zone)
        end
        
        # replace states like shutting-down with states like shutting_down
        attributes[:state].gsub!('-','_')

		# get security groups
		security_groups = []
		if reservation and reservation[:groups]
			security_groups = (account_security_groups.select{ |g| reservation[:groups].include?(g.name) })
		end
		
		instance = account_instances.detect{ |s| s.instance_id == attributes[:instance_id] }
		if instance.nil?
			instance = account.instances.build(attributes)
		else
			instance.attributes = attributes
		end
		instance.should_destroy = 0
		instance.security_groups = ( security_groups || [] )

		# get zone information
		unless zone_name.blank?
			zone = account_zones.detect{ |z| z.name == zone_name }
			if zone and !zone.instances.include?(instance)
  				zone.instances << instance
  			end
		end

		return instance	
	end

    def self.parse_snapshot_info(account, attributes)
		# mapping attributes
		attributes[:cloud_id] = attributes[:snapshot_id]
		attributes.delete(:snapshot_id)
		attributes[:parent_cloud_id] = attributes[:volume_id]
		attributes.delete(:volume_id)
		attributes[:state] = attributes[:status]
		attributes.delete(:status)

		return attributes
    end

	def self.create_snapshot(volume)
		return false if volume.nil?
		account = volume.provider_account
		ec2 = get_ec2(volume.provider_account)
		res = ec2.create_snapshot(volume.cloud_id)
		return parse_snapshot_info(account, res)
	end

    def self.delete_snapshot(snapshot)
        return nil if snapshot.nil?
        ec2 = get_ec2(snapshot.provider_account)
        ec2.delete_snapshot(snapshot.cloud_id)
    end

    def self.create_security_group(group)
        return false if group.nil?
        ec2 = get_ec2(group.provider_account)
        ec2.create_security_group(group.name, group.description)
    end

    def self.delete_security_group(group)
        return false if group.nil?
        ec2 = get_ec2(group.provider_account)
        ec2.delete_security_group(group.name)
    end

    def self.add_security_group_firewall_rule(security_group, firewall_rule)
        return false if security_group.nil? or firewall_rule.nil?
        ec2 = get_ec2(security_group.provider_account)
        if !firewall_rule.group_name.blank? and !firewall_rule.group_user_id.blank?
            ec2.authorize_ingress_by_group(security_group.name, firewall_rule.group_name, firewall_rule.group_user_id)
        else
            from_port = firewall_rule.from_port
            to_port = firewall_rule.to_port
            from_port = to_port = -1 if firewall_rule.protocol == 'icmp'
            ec2.authorize_ingress_by_cidr(security_group.name, firewall_rule.protocol, from_port, to_port, firewall_rule.ip_range)
        end
        security_group.firewall_rules << firewall_rule unless security_group.firewall_rules.include?(firewall_rule)
    end

    def self.remove_security_group_firewall_rule(security_group, firewall_rule)
        return false if security_group.nil? or firewall_rule.nil?
        ec2 = get_ec2(security_group.provider_account)
        if !firewall_rule.group_name.blank? and !firewall_rule.group_user_id.blank?
            ec2.revoke_ingress_by_group(security_group.name, firewall_rule.group_name, firewall_rule.group_user_id)
        else
            from_port = firewall_rule.from_port
            to_port = firewall_rule.to_port
            from_port = to_port = -1 if firewall_rule.protocol == 'icmp'
            ec2.revoke_ingress_by_cidr(security_group.name, firewall_rule.protocol, from_port, to_port, firewall_rule.ip_range)
        end
        security_group.firewall_rules.delete(firewall_rule) if security_group.firewall_rules.include?(firewall_rule)
    end

    def self.allocate_address(address)
        ec2 = get_ec2(address.provider_account)
        address.cloud_id = ec2.allocate_address
        return true
    end
    
    def self.release_address(address)
        ec2 = get_ec2(address.provider_account)
        ec2.release_address(address.cloud_id)
        return true
    end
    
    def self.register_server_image(server_image)
        ec2 = get_ec2(server_image.provider_account)
        image_id = ec2.register_image(server_image.location)
        return image_id
    end
    
    def self.deregister_server_image(server_image)
        ec2 = get_ec2(server_image.provider_account)
        ec2.deregister_image(server_image.image_id)
        return true
    end
end
