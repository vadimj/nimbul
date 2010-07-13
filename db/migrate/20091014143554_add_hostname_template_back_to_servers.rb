class AddHostnameTemplateBackToServers < ActiveRecord::Migration
	def self.up
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
	end

	def self.down
		remove_column :servers, :hostname_template
		remove_index :servers, [ :hostname_template, :cluster_id ]
	end
end
