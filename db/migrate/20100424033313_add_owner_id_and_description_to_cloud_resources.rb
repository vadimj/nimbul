class AddOwnerIdAndDescriptionToCloudResources < ActiveRecord::Migration
  def self.up
    add_column :cloud_resources, :owner_id, :string
    add_column :cloud_resources, :description, :string
    add_index :cloud_resources, :owner_id
    add_index :cloud_resources, :description
  end

  def self.down
    remove_column :cloud_resources, :description
    remove_column :cloud_resources, :owner_id
  end
end
