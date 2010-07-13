require 'hostname-registry'
require 'fileutils'
require 'pp'

class LDNS_Adapter

	@@registry = {}

	def self.add_server_hostname(server, hostname)
		DnsHostnameAssignment.create(server, hostname)
	end
	
    def self.get_registry(cluster)
		cluster_id = cluster[:id]

		unless @@registry[cluster_id].is_a? HostRegistry
			registry_path = File.join(
				LDNS_REGISTRY_PATH,
				'provider', cluster.provider_account_id.to_s,
				'cluster', cluster_id.to_s
			)

			groups = Cluster.find(cluster_id).servers.inject({}) do |hash, server|
				next if (host_key = HostRegistry.get_hostname_key(server)).nil?
				hash[host_key.to_sym] = HostRegistry.get_hostname_tpl(server)
				hash
			end

			@@registry[cluster_id] = HostRegistry.new(registry_path, groups || {})

			if not File.exists? registry_path
				FileUtils.mkdir_p registry_path
				@@registry[cluster_id].save_cache
			end

			@@registry[cluster_id].load_cache rescue true
		end

		@@registry[cluster_id].load_cache
		@@registry[cluster_id].cleanup_leases!

        return @@registry[cluster_id]
    end

	def self.remove_registry(cluster_or_provider)

		case cluster_or_provider.class.name.to_sym
			when :Cluster:
				cluster = cluster_or_provider
				registry_path = File.join(LDNS_REGISTRY_PATH, 'provider', cluster.provider_account_id.to_s, 'cluster', cluster[:id].to_s)
				FileUtils.rm_rf(registry_path)

				# once we've removed the local cache for the registries, then
				# simply deleting it from our list is sufficient to finalize the removal
				@@registry.delete(cluster[:id])

			when :ProviderAccount:
				provider = cluster_or_provider
				registry_path = File.join(LDNS_REGISTRY_PATH, 'provider', provider[:id].to_s)
				FileUtils.rm_rf(registry_path)

				# once we've removed the local cache for the registries, then
				# simply deleting it from our list is sufficient to finalize the removal
				@@registry.delete_if do |cluster_id,registry|
					providers_clusters = cluster_or_provider.clusters.inject([]) { |array,cluster| array << cluster[:id] }
					providers_clusters.include? cluster_id
				end
		else
			raise(Exception, "'#{cluster_or_provider.class.name}' is not a cluster or provider account")
		end

		@@registry
	end

	def self.handle_update(cluster, instance)
		return [0, 0] if cluster.nil? or instance.server.nil?

		# start importing hostnames and assignments into the database
		self.add_server_hostname(instance.server, instance.server.hostname_template) 
		
		registry = get_registry(cluster)
		result = registry.process_instance(instance)

		registry.save_cache(true)

		return result # [added, removed]
	end

	def self.get_host_entries(cluster_or_provider, options={})
        static = []
        unless options[:skip_static_dns]
    		static_dns_records = (cluster_or_provider.provider_account rescue cluster_or_provider).static_dns_records
            static = static_dns_records.split(/\r*\n/) unless static_dns_records.blank?
        end
		entries = {0 => { :name => 'static', :entries => {'static' => static } }}

		include_comments = options.has_key?(:include_server_info) ? (! options[:include_server_info]) : true;

		case cluster_or_provider.class.name.to_sym
			when :Cluster:
				cluster = cluster_or_provider
				provider = cluster.provider_account

				entries[cluster[:id]] = {
					:name    => cluster.name,
					:entries => get_registry(cluster).get_host_entries(options[:include_server_info])
				}

			when :ProviderAccount:
				provider = cluster_or_provider

				cluster_or_provider.clusters.each do |cluster|
					entries[cluster[:id]] = {
						:name    => cluster.name,
						:entries => get_registry(cluster).get_host_entries(options[:include_server_info])
					}
				end

		else
			raise(Exception, "'#{cluster_or_provider.class.name}' is not a cluster or provider account")
		end

		hostfile = []

		# these hosts file comments are required by User Community dbslayer/memcache
		# userland apps that parse the hosts file to get information they need.
		# Removing the comments can break functionality.

		hostfile.push "\n#### EC2LDNS START ####\n" if include_comments

		entries.sort.each do |cluster_id, cluster_data|
			hostfile.push "\n# Cluster START: #{cluster_data[:name]} #" if include_comments
			cluster_data[:entries].sort.each do |host_template, hosts|
				hostfile.push "\n# Group START: #{host_template} #\n" if include_comments
				hosts.each_index { |i| hostfile.push "#{hosts[i]}\n" }
				hostfile.push "# Group END: #{host_template} #\n" if include_comments
			end
			hostfile.push "#{"\n" if cluster_data[:entries].empty?}# Cluster END: #{cluster_data[:name]} #\n" if include_comments
		end

		hostfile.push "\n#### EC2LDNS END ####\n" if include_comments

		hostfile
	end

end
