class AddIsDefaultToResourceBundles < ActiveRecord::Migration
  def self.up
    add_column :resource_bundles, :is_default, :boolean
  end

  def self.down
    remove_column :resource_bundles, :is_default
  end
end
