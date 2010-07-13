class AddZoneIdToResourceBundles < ActiveRecord::Migration
  def self.up
    add_column :resource_bundles, :zone_id, :integer
    add_index :resource_bundles, :zone_id
  end

  def self.down
    remove_column :resource_bundles, :zone_id
  end
end
