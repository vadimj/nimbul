class AddMountPointToServerResources < ActiveRecord::Migration
  def self.up
    add_column :server_resources, :mount_point, :string
  end

  def self.down
    remove_column :server_resources, :mount_point
  end
end
