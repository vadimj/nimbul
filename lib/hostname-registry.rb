require 'socket'

class HostRegistry
	STATE_ACTIVE   = 'isup'
	STATE_INACTIVE = 'isdown'

	REGISTRY_FILE = 'hostname-leases.registry';
	DEFAULT_RENDER_TEMPLATE = '{{HOSTNAME}} {{STATE}} {{INSTANCE_ID}} {{CLUSTER_NAME}} {{SERVER_NAME}} {{ROLES}} {{PUBLIC_DNS}} {{SIMPLIFIED_HOSTNAME}}'

	def initialize(cache_path, mappings, render_template = nil)
		@digest = ''

		@mappings = mappings

		@log = Rails.logger

		@render_template = render_template.nil? ? DEFAULT_RENDER_TEMPLATE : render_template

		@registry = {
			# the next available increment number for a given groupname
			# incrementals[gropuname] = value
			:incrementals => {},

			# list of hostnames that have been previously used (per group)
			# but are currently not in use
			# available[groupname] = [name, name, name, etc]
			:available => {},

			# list of hostnames currently leased out and the instance id that has it
			# note: this is also per group (ie., registry[groupname][hostname] = { id, index, ipaddr, state } )
			:leases    => {},

			# list of instance id's and the hostnames they currently have leased out (by groupname)
			:reverse   => {},

			# list of instance ids that we have seen running recently
			:mapped_running  => [],
		}

		@registry_file = File.join(cache_path, REGISTRY_FILE);
	end

	def get_all() @registry; end

	def load_cache()
		begin
			@registry = Marshal.restore(IO.read(@registry_file).to_s)
		rescue
			@log.info(sprintf("Unable to load cache from file [%s] - error was: %s", @registry_file, $!))
		end
	end

	def save_cache(force = false)
		# only update the cache if it needs updating
		new_digest = Digest::MD5.hexdigest(Marshal.dump(@registry))
		if (@digest != new_digest or force)
			@digest = new_digest
			begin
				File.open(@registry_file, 'w') { |f| f << Marshal.dump(@registry) }
			rescue
				@log.info(sprintf("Unable to save lease cache to file [%s] - error was: %s", @registry_file, $!))
			end
		end
	end

	def cleanup_leases!()

		instances = Instance.find_all_by_instance_id(@registry[:reverse].keys).inject({}) { |h,i| h[i.instance_id] = i; h }
		unless instances.nil?
			@registry[:reverse].each do |id, groups|
				# if the instance_id wasn't found in the list of instances, or if it was but it's not running, remove it
				if not instances.keys.include?(id) or not instances[id].running?
					@registry[:mapped_running].delete(id)
				end
			end
		end

		# remove missing instances
		@registry[:reverse].each do |id,groups|
			if not @registry[:mapped_running].include?(id)
				@log.info(sprintf("Removing all leases for terminated instance '%s' from registry.", id))
				remove_all_leases(id)
			end
		end

		# remove missing groups
		(@registry[:leases].keys + @registry[:available].keys + @registry[:incrementals].keys).uniq.each do |group|
			if @mappings.nil?
				@log.info(sprintf("Removing lease information for missing group '%s' from registry", group))
				@registry[:leases].delete(group)
				@registry[:available].delete(group)
				@registry[:incrementals].delete(group)
			end
		end

		save_cache()
	end

	def has_lease?(instance_id, groupname)
		reverse = @registry[:reverse]
		leases  = @registry[:leases]

		begin
			hostname = (defined?(reverse[instance_id][groupname]) ? reverse[instance_id][groupname] : nil)
			return (not hostname.nil? and leases[groupname][hostname][:id] == instance_id)
		rescue
			@log.error("instance_id [#{instance_id}] currently has no leased hostname in the group [#{groupname}]")
			return false
		end

	end

	def acquire_lease(host, groupname)
		instance_id = host[:id]
		return if (has_lease?(instance_id, groupname))

		@registry[:leases][groupname] ||= {}
		@registry[:incrementals][groupname] ||= 0

		#  1. get hostname
		#    1.a. try to get an available (previously used) hostname removing
		#	 it from the list of available if there is one
		#    1.b. failing that, acquire one using the template provided for the group
		#  2. Add the hostname -> instance-id to the leases list as well as reverse list
		#  3. Ensure that the hostname has been removed from the 'available' list
		#     if it was previously in there

		begin
			# try to get an available hostname first, popping the hostname
			# from the list of available (so it's removed). We also grab the
			# previous index that the given host name had so we can reuse it
			hostname = @registry[:available][groupname].sort.shift or raise NoMethodError
			index    = @registry[:leases][groupname][hostname][:index]
			@log.info(sprintf("Reassigning lease for '%s' to instance '%s'", hostname, instance_id))
		rescue NoMethodError
			# otherwise we use the template in the hostname mapping for this group
			template = @mappings[groupname.to_sym].gsub(/^\s*([^\s]+)\s*.*/, '\1') rescue nil

			if template.nil?
				@log.error(sprintf('Missing template for group [%s] - unable to add host entry for instance [%s]', groupname, instance_id))
				return
			end

			# attempt to get the incremental for this group, falling back to
			# zero if it hasn't yet been set up, and then set the next incremental
			# for the group to the current + 1
			index = incremental = (@registry[:incrementals][groupname] rescue 0)
			@registry[:incrementals][groupname] = (incremental + 1)

			# now create the hostname based on the template
			begin
				hostname = sprintf(template, incremental)
			rescue
				@log.error(sprintf('Problem with template: [%s]. Error was: %s', template, $!))
				hostname = template
			ensure
				hostname.gsub!('{{INCREMENT}}', sprintf('%05d', incremental));
			end

			@log.info(sprintf("Assigning lease for '%s' to instance '%s'", hostname, instance_id))
		ensure
			@registry[:leases][groupname][hostname] ||= {}
			@registry[:leases][groupname][hostname][:state]  = STATE_ACTIVE
			@registry[:leases][groupname][hostname][:id]     = instance_id
			@registry[:leases][groupname][hostname][:ipaddr] = host[:ipaddr]
			@registry[:leases][groupname][hostname][:index]  = index

			@registry[:reverse][instance_id] ||= {}
			@registry[:reverse][instance_id][groupname] = hostname

			# make sure that the hostname has been removed from the
			# list of available hostnames for this group
			begin
				if @registry[:available][groupname].include?(hostname)
					@registry[:available][groupname].delete(hostname)
				end
			rescue NoMethodError
				@registry[:available][groupname] = []
			end

			@log.info(sprintf("Lease on hostname '%s' successfully created for instance id '%s'", hostname, instance_id))
		end
	end

	def remove_lease(host, groupname)
		instance_id = host[:id]
		return if (not has_lease?(instance_id, groupname))

		hostname = @registry[:reverse][instance_id][groupname] rescue nil

		if (not hostname.nil?)
			# add the hostname to the available list so it can be reused
			# immediately if need be
			@registry[:available][groupname].push(hostname)

			# Mark this lease as inactive but still allow it to be displayed
			# in the hosts file so applications that parse the /etc/hosts file
			# can handle this state in a way that makes for them. Note:
			# this lease will be overwritten by the next instance that needs
			# a hostname from the given group, until then we just mark it
			# inactive and nil the instance id
			@registry[:leases][groupname][hostname][:state]  = STATE_INACTIVE
			@registry[:leases][groupname][hostname][:id]     = ""
			# Additional note: we don't erase the ipaddr nor the index fields
			# because we need to maintain the exact order when dumped to /etc/hosts

			# remove the group from this particular instance
			@registry[:reverse][instance_id].delete(groupname)
			@log.info("Lease on hostname '#{hostname}' successfully removed for instance '#{instance_id}'")
		end
	end

	def remove_all_leases(instance_id)
        unless @registry[:reverse][instance_id].nil?
    		@registry[:reverse][instance_id].each do |groupname, hostname|
	    		remove_lease({:id => instance_id, :ipaddr => nil, :index => 0, :state => STATE_INACTIVE}, groupname)
		    end
        end

		@registry[:reverse].delete(instance_id)
		Instance.find(instance_id).release_dns_leases rescue nil # release if instance isn't already gone
		return true
	end

	def self.get_hostname_key(server)
		# FIXME: this should not include the cluster id. remove this later
		# and update ldns_adapter so that it doesn't attempt to remove it itself
		sprintf('%s', (server.hostname_template || ''))
	end

	def self.get_hostname_tpl(server)
		cluster_name = server.cluster.name rescue 'Unknown Cluster'
		cluster_name.gsub!(/[^\w\d]+/, '_')
		sprintf('%s-{{INCREMENT}}-%s', (server.hostname_template || ''), cluster_name.downcase)
	end

	def process_instance(instance)
		added = removed = 0

		instance_id = instance.instance_id

		catch :done do
			server = Server.find(instance.server_id)
			if server.nil? or (host_tpl = self.class.get_hostname_key(server)).nil? or not @mappings.has_key?(host_tpl.to_sym)
				@log.info("No hostname mapping configured for instance [#{instance_id}] - skipping")
				throw :done
			end

			current_state = instance.state
			current_state = 'terminated' if not instance.ready?

			case current_state
				when 'running'
					if not instance.ready? or instance.private_ip.nil?
						@log.info("Instance '#{instance_id}' not ready or missing private IP address - skipping")
						throw :done
					end

					hostinfo= { :id => instance_id, :ipaddr => instance.private_ip }

					acquire_lease(hostinfo, host_tpl)
					instance.acquire_dns_leases

					added += 1

					# add to list of known running instances which we can use during cleanup
					@registry[:mapped_running].push(instance_id) if not @registry[:mapped_running].include?(instance_id)
					
					
				when 'terminated', 'shutting-down'
					instance.release_dns_leases
					if has_lease?(instance_id, host_tpl)
						remove_all_leases(instance_id)
						removed += 1

						# remove from the list of running instances - useful during cleanup
						@registry[:mapped_running].delete(instance_id) if @registry[:mapped_running].include?(instance_id)
					end
					
					
				when 'pending'
					# do nothing - only handle once the instance has actually started up
			else
				@log.info("Unhandled state [#{current_state}]...!")
			end
		end

		if (added > 0 || removed > 0)
			self.save_cache()
		end

		return added, removed
	end

	def get_host_entries(include_server_info = false)
		entries = {}
		@registry[:leases].each do |groupname, hosts|
			entries[groupname] ||= []
			hosts.each do |hostname, hostdata|

				begin
					data_keys = hostdata.keys.sort { |a,b| a.to_s <=> b.to_s }
					req_keys = [ :id, :index, :state, :ipaddr ].sort { |a,b| a.to_s <=> b.to_s }
					keys_are_valid = (data_keys == req_keys)		
				rescue
					keys_are_valid = false
				end
				
				if (!hostdata.is_a?(Hash) || !keys_are_valid || hostdata.length != 4 ||
				   hostdata[:index].blank? || hostdata[:ipaddr].blank?)
						@log.error("Lease information hostname #{groupname}:#{hostname} is corrupt - skipping!!")
						next
				end
                                
				hostinfo = @render_template.dup

				hostinfo.gsub!('{{HOSTNAME}}', hostname)
				hostinfo.gsub!('{{STATE}}', hostdata[:state])
				hostinfo.gsub!('{{INSTANCE_ID}}', hostdata[:id]) rescue nil

				if include_server_info
					i = Instance.find_by_instance_id(hostdata[:id])
					unless i.nil?
						simplified_hostname = hostname.gsub(/([^\d]+\d{5,5})-.*/, '\1') rescue nil
						server = Server.find(i.server_id, :include => [ :cluster ]) rescue Server.new
						cluster_name = server.cluster.name.gsub(' ','_') rescue nil
						server_name = server.name.gsub(' ','_') rescue nil
						roles = server.get_server_parameter('ROLES') rescue nil
						hostinfo.gsub!('{{CLUSTER_NAME}}', cluster_name || 'Unknown_Cluster')
						hostinfo.gsub!('{{SERVER_NAME}}', server_name || 'Unknown_Server')
						hostinfo.gsub!('{{ROLES}}', roles || 'base')
						hostinfo.gsub!('{{PUBLIC_DNS}}', i.public_dns || 'Unknown_Public_Hostname')
						hostinfo.gsub!('{{SIMPLIFIED_HOSTNAME}}', simplified_hostname || 'Unknown_Hostname')
					end
				else
					hostinfo.gsub!('{{CLUSTER_NAME}}', '')
					hostinfo.gsub!('{{SERVER_NAME}}', '')
					hostinfo.gsub!('{{ROLES}}', '')
					hostinfo.gsub!('{{PUBLIC_DNS}}', '')
					hostinfo.gsub!('{{SIMPLIFIED_HOSTNAME}}', '')
				end

				entries[groupname][hostdata[:index]] = sprintf('%-17s %s', hostdata[:ipaddr], hostinfo)
			end
			# clean up nil entries which can appear if we have indexes that are non-contiguous
			entries[groupname] = entries[groupname].select { |e| !e.nil? }
		end

		return entries
	end
end


module HostFile
	DEFAULT_HOST_FILE = '/etc/hosts'
	EC2_DELIMITER_START = "#### EC2LDNS START ####\n";
	EC2_DELIMITER_STOP  = "#### EC2LDNS END ####\n"

	def self.update(hosts, file_path = nil)
		file_path ||= DEFAULT_HOST_FILE

		hostfile = get_hostfile(file_path)

		hostfile.push("\n") if (hostfile.last !~ /^\s*$/);

		hostfile.push(EC2_DELIMITER_START)

		hosts.each do |groupname,group|
			hostfile.push("\n# Group START: #{groupname} #\n")
			group.each_index do |idx|
				hostfile.push(sprintf("%s\n", group[idx]))
			end
			hostfile.push("# Group END: #{groupname} #\n")
		end

		hostfile.push("\n" + EC2_DELIMITER_STOP)

		File.open(file_path, 'w') { |f| f << hostfile.to_s }
	end

	def self.find_markers(hostdata)
		start,stop = -1,-1
		hostdata.each_index do |idx|
			if start < 0
				start = idx if (hostdata[idx] =~ /^#{EC2_DELIMITER_START}/)
			elsif stop < 0
				stop = idx if (hostdata[idx] =~ /^#{EC2_DELIMITER_STOP}/)
			end
		end

		if start > 0
			stop = (hostdata.length - 1) unless stop >= start
			return start,stop
		else
			return (hostdata.length - 1), (hostdata.length - 1)
		end
	end

	def self.get_hostfile(file_path)
		hostfile = IO.readlines(file_path)
		start,stop = find_markers(hostfile)

		if (start < hostfile.index(hostfile.last) and (stop - start) > 0)
			hostfile.slice!(start, stop)
		end
		return hostfile
	end
end
