class AddOwnerIdAndDescriptionToSnapshots < ActiveRecord::Migration
  def self.up
    add_column :snapshots, :owner_id, :string
    add_column :snapshots, :description, :string
    add_index :snapshots, :owner_id
    add_index :snapshots, :description
  end

  def self.down
    remove_column :snapshots, :description
    remove_column :snapshots, :owner_id
  end
end
