class RemoveZoneFromInstanceAllocationRecords < ActiveRecord::Migration
  def self.up
    remove_column :instance_allocation_records, :zone 
  end

  def self.down
    add_column :instance_allocation_records, :zone, :string
  end
end
