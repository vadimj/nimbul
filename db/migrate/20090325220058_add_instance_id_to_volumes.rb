class AddInstanceIdToVolumes < ActiveRecord::Migration
  def self.up
	add_column :volumes, :instance_id, :string
	add_index :volumes, :instance_id
  end

  def self.down
	remove_column :volumes, :instance_id
  end
end
