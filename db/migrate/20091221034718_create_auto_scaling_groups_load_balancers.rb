class CreateAutoScalingGroupsLoadBalancers < ActiveRecord::Migration
  def self.up
    create_table :auto_scaling_groups_load_balancers, :id => false do |t|
      t.integer :auto_scaling_group_id, :load_balancer_id
    end
    add_index :auto_scaling_groups_load_balancers, :auto_scaling_group_id, :name => 'asglb_asg_id_index'
    add_index :auto_scaling_groups_load_balancers, :load_balancer_id, :name => 'asglb_lb_id_index'
  end

  def self.down
    drop_table :auto_scaling_groups_load_balancers
  end
end
