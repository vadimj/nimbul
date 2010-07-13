require 'ostruct'
require 'pp'

class AddProviderAccountIdToDnsHostnamesAndConvertData < ActiveRecord::Migration
	def self.up
		remove_column :instances, :dns_assignable
		add_column :instances, :dns_active, :boolean, :default => 1

		Instance.reset_column_information

		add_column :dns_hostnames, :provider_account_id, :integer, :null => false, :sign => :unsigned rescue nil
		add_index :dns_hostnames, [ :provider_account_id, :name ], :unique => true, :name => 'unique_provider_account_hostname' rescue nil
		
		begin
			DnsHostname.reset_column_information

			list = DnsHostnameAssignment.find(:all).inject({}) do |h,o|
				if not o.dns_hostname.nil?
					d = OpenStruct.new
					d.assignment = o
					d.hostname = o.dns_hostname_id
					d.server = o.server_id 
				
					(h[o.server.cluster.provider_account_id] ||= []).push(d) rescue nil
				end
				h
			end
			
			list.each do |pa_id, server_hosts|
				puts "--- Working on Provider Account '#{ProviderAccount.find(pa_id).name}' ---"
				server_hosts.each do |d|
					server = Server.find(d.server)
					hostname = DnsHostname.find(d.hostname)
					
					DnsHostname.cache do 
						begin
							if hostname.provider_account.nil? or hostname.provider_account_id == 0
								puts "      M - #{hostname.name} is missing a provider_account_id - setting it to '#{pa_id}'"
								hostname.update_attribute(:provider_account_id, pa_id)
								next
							elsif hostname.provider_account_id != pa_id
								assignment = DnsHostnameAssignment.create(server, hostname.name)
								
								if assignment.nil?
									puts "      F - #{hostname.name} - Failed to create new hostname assignment.."
									next
								end
								
								puts  "      C - #{hostname.name} is already owned by '#{hostname.provider_account.name}' - creating a new one for this account."
								d.assignment.dns_leases.each do |l|
									l.update_attribute(:dns_hostname_assignment_id, assignment.id)
								end
								d.assignment.destroy
							else
								puts "       ? - not nil, not 0 and not already assigned"
							end
						rescue Exception => e
							puts "Hostname: #{hostname.inspect}"
							puts "Server: #{server.inspect}"
							raise e
						end
					end
				end
			end
		rescue Exception => e
			self.down
			raise e
		end

		# last but not least, remove the hostname_template column		
		remove_column :servers, :hostname_template rescue nil
		Server.reset_column_information
	end

	def self.down
		remove_index :dns_hostnames, :name => 'unique_provider_account_hostname' rescue nil
		remove_column :dns_hostnames, :provider_account_id rescue nil
		
		DnsHostname.reset_column_information

		remove_column :instances, :dns_active rescue nil
		add_column :instances, :dns_assignable, :boolean, :default => 1 rescue nil
		
		Instance.reset_column_information
	end
end

true
