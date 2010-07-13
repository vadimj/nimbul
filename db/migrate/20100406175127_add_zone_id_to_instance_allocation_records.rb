class AddZoneIdToInstanceAllocationRecords < ActiveRecord::Migration
  def self.up
    add_column :instance_allocation_records, :zone_id, :integer
    add_index :instance_allocation_records, :zone_id
  end

  def self.down
    remove_column :instance_allocation_records, :zone_id
  end
end
