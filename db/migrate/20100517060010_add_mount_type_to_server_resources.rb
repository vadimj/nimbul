class AddMountTypeToServerResources < ActiveRecord::Migration
  def self.up
    add_column :server_resources, :mount_type, :string
  end

  def self.down
    remove_column :server_resources, :mount_type
  end
end
