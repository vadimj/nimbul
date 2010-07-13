class AddZoneIdToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :zone_id, :integer
    add_index :servers, :zone_id
  end

  def self.down
    remove_column :servers, :zone_id
  end
end
