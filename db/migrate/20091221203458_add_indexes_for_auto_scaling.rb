class AddIndexesForAutoScaling < ActiveRecord::Migration
  def self.up
    # auto_scaling_groups
    add_index :auto_scaling_groups, :provider_account_id, :name => 'index_pa_id_on_asg'
    add_index :auto_scaling_groups, :launch_configuration_id, :name => 'index_lc_id_on_asg'
    
    # auto_scaling_triggers
	add_index :auto_scaling_triggers, :provider_account_id, :name => 'index_pa_id_on_asgt'
    add_index :auto_scaling_triggers, :auto_scaling_group_id, :name => 'index_asg_id_on_asgt'
	
    # auto_scaling_groups_instances
    add_index :auto_scaling_groups_instances, :auto_scaling_group_id, :name => 'index_asg_id_on_asgi'
    add_index :auto_scaling_groups_instances, :instance_id, :name => 'index_i_id_on_asgi'
  end

  def self.down
    remove_index :auto_scaling_groups, :name => 'index_pa_id_on_asg'
    remove_index :auto_scaling_groups, :name => 'index_lc_id_on_asg'
    
    # auto_scaling_triggers
	remove_index :auto_scaling_triggers, :name => 'index_pa_id_on_asgt'
    remove_index :auto_scaling_triggers, :name => 'index_asg_id_on_asgt'
	
    # auto_scaling_groups_instances
    remove_index :auto_scaling_groups_instances, :name => 'index_asg_id_on_asgi'
    remove_index :auto_scaling_groups_instances, :name => 'index_i_id_on_asgi'
  end
end
