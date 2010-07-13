class RemoveIdFromAutoScalingGroupsInstancesTable < ActiveRecord::Migration
  def self.up
	  remove_column :auto_scaling_groups_instances, :id
  end

  def self.down
	  add_column :auto_scaling_groups_instances, :id, :integer
  end
end
