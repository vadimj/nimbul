class AddIndexToInstanceAllocationRecordsOnStatRecordId < ActiveRecord::Migration
  def self.up
    add_index :instance_allocation_records, :stat_record_id, :name => 'index_iars_on_srids'
  end

  def self.down
    remove_index :instance_allocation_records, :name => 'index_iars_on_srids'
  end
end
