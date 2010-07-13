class RemoveEnumFromAutoScalingGroupsState < ActiveRecord::Migration
  def self.up
    remove_column :auto_scaling_groups, :state
    add_column :auto_scaling_groups, :state, :string, :default => :disabled
  end

  def self.down
    remove_column :auto_scaling_groups, :state
    add_column :auto_scaling_groups, :state, :enum, :limit => [ :disabled, :active ], :default => :disabled
  end
end
