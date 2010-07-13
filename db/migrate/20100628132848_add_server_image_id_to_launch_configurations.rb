class AddServerImageIdToLaunchConfigurations < ActiveRecord::Migration
  def self.up
    add_column :launch_configurations, :server_image_id, :integer
    add_index :launch_configurations, :server_image_id
  end

  def self.down
    remove_column :launch_configurations, :server_image_id
  end
end
