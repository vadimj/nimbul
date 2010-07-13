class AddZoneIdToReservedInstances < ActiveRecord::Migration
  def self.up
    add_column :reserved_instances, :zone_id, :integer
    add_index :reserved_instances, :zone_id
    remove_column :reserved_instances, :zone
  end

  def self.down
    add_column :reserved_instances, :zone, :string
    add_index :reserved_instances, :zone
    remove_column :reserved_instances, :zone_id
  end
end
