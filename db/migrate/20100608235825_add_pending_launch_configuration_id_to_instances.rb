class AddPendingLaunchConfigurationIdToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :pending_launch_configuration_id, :integer
  end

  def self.down
    remove_column :instances, :pending_launch_configuration_id
  end
end
