class CreateAutoScalingGroupsInstances < ActiveRecord::Migration
  def self.up
    create_table :auto_scaling_groups_instances do |t|
      t.integer :auto_scaling_group_id
      t.integer :instance_id
      t.timestamps
    end
  end

  def self.down
    drop_table :auto_scaling_groups_instances
  end
end
