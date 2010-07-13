class RemoveUniqueDnsHostnameServerIdIndexAndUniqueAddDnsHostnameIdIndex < ActiveRecord::Migration
	def self.up
		add_index :dns_hostname_assignments, [ :dns_hostname_id ], :unique => true, :name => 'unique_dns_hostname_id_idx' 
		remove_index :dns_hostname_assignments, :name => 'unique_server_hostname_idx' 
	end

	def self.down
		add_index :dns_hostname_assignments, [ :server_id, dns_hostname_id ], :unique => true, :name => 'unique_server_hostname_idx' 
		remove_index :dns_hostname_assignments, :name => 'unique_dns_hostname_id_idx' 
	end
end
