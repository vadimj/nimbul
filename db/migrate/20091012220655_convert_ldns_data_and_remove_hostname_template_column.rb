class ConvertLdnsDataAndRemoveHostnameTemplateColumn < ActiveRecord::Migration
	def self.up
		Server.find(:all).each do |s|
			ha = LDNS_Adapter.add_server_hostname(s, s[:hostname_template])
			Rails.logger.info "Adding new hostname assignment for host '#{s[:hostname_template]}' to server ##{s.id} - hostname id: ##{ha.dns_hostname_id}"
		end
		
		Rails.logger.info "Removing 'hostname_template' column from Servers table"
		remove_column :servers, :hostname_template
		remove_index :servers, [ :hostname_template, :cluster_id ]
			
		# now populate the new database backend with data from
		# the old ldns serialized flatfile backend
		
		begin
			Cluster.find(:all).sort!{ |a,b| a.id <=> b.id }.each do |cluster|
				Rails.logger.info "Beginning import of cluster #{cluster.id}:#{cluster.name}"

				registry = LDNS_Adapter.get_registry(cluster).get_all
				
				hostname_mappings = {}
				cluster.servers.each do |server|
					ha = DnsHostnameAssignment.find_by_server_id(server.id)
					hostname_mappings[ha.name.to_sym] = ha
				end

				Rails.logger.info "-- Processing Incrementals for cluster ##{cluster.id}:#{cluster.name}: "

				registry[:incrementals].each do |hostname, count|
					next if hostname_mappings[hostname.to_sym].nil?
					
					(0..(count-1)).each do |idx|
						Rails.logger.info "---- Creating new unassigned lease for hostname '#{hostname}' at index ##{idx}"
						DnsLease.new(
							:dns_hostname_assignment_id => (hostname_mappings[hostname.to_sym].id rescue next),
							:instance_id => nil,
							:idx => idx
						).save
					end
				end
				
				registry[:leases].each do |hostname, host_data|
					Rails.logger.info "-- Collating host data for '#{hostname}'"
					host_data.values.each do |data|
						next if data[:state] == HostRegistry::STATE_INACTIVE

						i = Instance.find_by_instance_id(data[:id])
						lease = DnsLease.find_by_dns_hostname_assignment_id_and_idx(
							hostname_mappings[hostname.to_sym].id,
							data[:index]
						)
						lease.instance = i
						lease.save

						Rails.logger.info "---- Assigning lease for host '#{lease.fqdn}' to instance '#{data[:id]}'"
					end
				end
			end
		rescue Exception => e
			puts "Error: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
			self.down
			raise
		end
	end
	
	def self.down
		# add hostname_template back to servers
		Rails.logger.info "Adding column 'hostname_template' back to 'servers' table."
		add_column :servers, :hostname_template, :string

		Rails.logger.info "Recreating Index (hostname_template, cluster_id) on table 'servers'"
		add_index :servers, [ :hostname_template, :cluster_id ]
		
		Rails.logger.info "Rebuilding column information on Server Object"
		Server.reset_column_information

		begin		
			# and repopulate the server.hostname_template attribute
			DnsHostnameAssignment.find(:all).each do |ha|
				s = ha.server || next
				s[:hostname_template] = ha.name
				s.save
				Rails.logger.info "-- Reverted Server ##{s.id} hostname_template to '#{ha.name}'"
			end
		rescue Exception => e
			puts "Error: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
			raise
		end

		Rails.logger.info "Deleting DnsRequest Data"
		DnsRequest.delete_all

		Rails.logger.info "Deleting DnsLease Data"
		DnsLease.delete_all

		Rails.logger.info "Deleting DnsHostnameAssignment Data"
		DnsHostnameAssignment.delete_all

		Rails.logger.info "Deleting DnsHostname Data"
		DnsHostname.delete_all
	end
end
