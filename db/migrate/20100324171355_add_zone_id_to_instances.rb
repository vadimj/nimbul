class AddZoneIdToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :zone_id, :integer
    add_index :instances, :zone_id
  end

  def self.down
    remove_column :instances, :zone_id
  end
end
