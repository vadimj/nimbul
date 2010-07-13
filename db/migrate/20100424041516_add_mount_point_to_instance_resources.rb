class AddMountPointToInstanceResources < ActiveRecord::Migration
  def self.up
    add_column :instance_resources, :mount_point, :string
  end

  def self.down
    remove_column :instance_resources, :mount_point
  end
end
