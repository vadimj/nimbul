class RecreateAutoScalingGroupsInstancesTable < ActiveRecord::Migration
  def self.up
	drop_table :auto_scaling_groups_instances
    create_table :auto_scaling_groups_instances, :id => false do |t|
      t.integer :auto_scaling_group_id, :i_id
    end
    
    # auto_scaling_groups_instances
    add_index :auto_scaling_groups_instances, :auto_scaling_group_id, :name => 'index_asg_id_on_asgi'
    add_index :auto_scaling_groups_instances, :i_id, :name => 'index_i_id_on_asgi'

	AutoScalingGroup.reset_column_information
	Instance.reset_column_information
  end

  def self.down
	drop_table :auto_scaling_groups_instances
  end
end
