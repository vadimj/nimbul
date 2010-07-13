class RemoveZoneFromInstances < ActiveRecord::Migration
  def self.up
    remove_column :instances, :zone 
  end

  def self.down
    add_column :instances, :zone, :string
  end
end
