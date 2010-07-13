class AddInstancesSecurityGroupsTable < ActiveRecord::Migration
	def self.up
		#generate the join table
		create_table "instances_security_groups", :id => false do |t|
			t.integer "instance_id", "security_group_id"
		end
		add_index "instances_security_groups", "instance_id"
		add_index "instances_security_groups", "security_group_id"
	end

	def self.down
		drop_table "instances_security_groups"
	end
end
