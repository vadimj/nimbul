class AddServerResourcesCountToCloudResources < ActiveRecord::Migration
  def self.up
    add_column :cloud_resources, :server_resources_count, :integer, :default => 0
  end

  def self.down
    remove_column :cloud_resources, :server_resources_count
  end
end
