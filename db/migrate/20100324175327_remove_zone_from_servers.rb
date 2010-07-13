class RemoveZoneFromServers < ActiveRecord::Migration
  def self.up
    remove_column :servers, :availability_zone 
  end

  def self.down
    add_column :servers, :availability_zone, :string
  end
end
