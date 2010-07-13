class AddMountTypeToInstanceResources < ActiveRecord::Migration
  def self.up
    add_column :instance_resources, :mount_type, :string
  end

  def self.down
    remove_column :instance_resources, :mount_type
  end
end
