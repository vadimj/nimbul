class AddZoneIdToVolumes < ActiveRecord::Migration
  class Volume < ActiveRecord::Base
  end
  
  def self.up
    add_column :volumes, :zone_id, :integer
    add_index :volumes, :zone_id
  end

  def self.down
    remove_column :volumes, :zone_id
  end
end
