class AddIsEnabledToServerImages < ActiveRecord::Migration
  def self.up
    add_column :server_images, :is_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :server_images, :is_enabled
  end
end
