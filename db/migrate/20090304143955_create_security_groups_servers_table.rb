class CreateSecurityGroupsServersTable < ActiveRecord::Migration
	def self.up
		#generate the join table
		create_table "security_groups_servers", :id => false do |t|
			t.integer "security_group_id", "server_id"
		end
		add_index "security_groups_servers", "security_group_id"
		add_index "security_groups_servers", "server_id"
	end

	def self.down
		drop_table "security_groups_servers"
	end
end
