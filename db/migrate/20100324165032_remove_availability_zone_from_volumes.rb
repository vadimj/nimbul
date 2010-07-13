class RemoveAvailabilityZoneFromVolumes < ActiveRecord::Migration
  def self.up
    remove_column :volumes, :availability_zone 
  end

  def self.down
    add_column :volumes, :availability_zone, :string
  end
end
