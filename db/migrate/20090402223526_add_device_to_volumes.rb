class AddDeviceToVolumes < ActiveRecord::Migration
  def self.up
	add_column :volumes, :device, :string
  end

  def self.down
	remove_column :volumes, :device
  end
end
