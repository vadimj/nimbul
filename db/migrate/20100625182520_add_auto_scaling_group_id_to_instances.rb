class AddAutoScalingGroupIdToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :auto_scaling_group_id, :integer
    add_index :instances, :auto_scaling_group_id
  end

  def self.down
    remove_column :instances, :auto_scaling_group_id
  end
end
