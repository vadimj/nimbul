class AddServerProfileRevisionIdToLaunchConfigurations < ActiveRecord::Migration
	def self.up
		add_column :launch_configurations, :server_profile_revision_id, :integer
	end

	def self.down
		remove_column :launch_configurations, :server_profile_revision_id
	end
end
