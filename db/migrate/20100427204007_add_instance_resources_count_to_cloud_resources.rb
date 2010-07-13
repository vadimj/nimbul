class AddInstanceResourcesCountToCloudResources < ActiveRecord::Migration
  def self.up
    add_column :cloud_resources, :instance_resources_count, :integer, :default => 0
  end

  def self.down
    remove_column :cloud_resources, :instance_resources_count
  end
end
