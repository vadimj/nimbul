class AddResourceBundleIdToServerResources < ActiveRecord::Migration
  def self.up
    add_column :server_resources, :resource_bundle_id, :integer
    add_index :server_resources, :resource_bundle_id
    remove_column :server_resources, :server_id
  end

  def self.down
    add_column :server_resources, :server_id, :integer
    add_index :server_resources, :server_id
    remove_column :server_resources, :resource_bundle_id
  end
end
