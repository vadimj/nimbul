class AddIsEnabledToVolumes < ActiveRecord::Migration
  def self.up
    add_column :volumes, :is_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :volumes, :is_enabled
  end
end
