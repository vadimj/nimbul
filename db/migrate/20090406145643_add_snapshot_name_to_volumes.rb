class AddSnapshotNameToVolumes < ActiveRecord::Migration
  def self.up
	add_column :volumes, :snapshot_name, :string
	add_index :volumes, :snapshot_name
  end

  def self.down
	remove_column :volumes, :snapshot_name
  end
end
