class CreateAutoScalingGroupsAvailabilityZones < ActiveRecord::Migration
  def self.up
    create_table :auto_scaling_groups_availability_zones, :id => false do |t|
      t.integer :auto_scaling_group_id, :availability_zone_id
    end
    add_index :auto_scaling_groups_availability_zones, :auto_scaling_group_id, :name => 'asgaz_asg_id_index'
    add_index :auto_scaling_groups_availability_zones, :availability_zone_id, :name => 'asgaz_az_id_index'
  end

  def self.down
    drop_table :auto_scaling_groups_availability_zones
  end
end
