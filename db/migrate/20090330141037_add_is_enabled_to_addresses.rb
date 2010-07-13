class AddIsEnabledToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :is_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :addresses, :is_enabled
  end
end
