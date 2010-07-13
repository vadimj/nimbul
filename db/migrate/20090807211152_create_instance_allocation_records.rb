class CreateInstanceAllocationRecords < ActiveRecord::Migration
  def self.up
    create_table :instance_allocation_records do |t|
      t.integer :stat_record_id
      t.integer :cluster_id
      t.string :cluster_name, :default => 'Default'
      t.integer :server_id
      t.string :server_name, :default => 'Default'
      t.string :zone
      t.string :instance_type
      t.integer :running

      t.timestamps
    end
  end

  def self.down
    drop_table :instance_allocation_records
  end
end
