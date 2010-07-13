class AddStateToLaunchConfigurations < ActiveRecord::Migration
  def self.up
    add_column :launch_configurations, :state, :string
    add_index :launch_configurations, [ :provider_account_id, :launch_configuration_name ], :unique => true, :name => :unique_provider_account_id_launch_configuration_name
  end

  def self.down
    remove_column :launch_configurations, :state
    remove_index :launch_configurations, :name => :unique_provider_account_id_launch_configuration_name
  end
end
