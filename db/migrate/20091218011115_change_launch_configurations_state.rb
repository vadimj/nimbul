class ChangeLaunchConfigurationsState < ActiveRecord::Migration
  def self.up
    remove_column :launch_configurations, :state
    add_column :launch_configurations, :state, :enum, :limit => [ :disabled, :active ], :default => :disabled
  end

  def self.down
    remove_column :launch_configurations, :state
    add_column :launch_configurations, :state, :string
  end
end
