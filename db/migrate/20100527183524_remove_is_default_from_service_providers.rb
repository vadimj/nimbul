class RemoveIsDefaultFromServiceProviders < ActiveRecord::Migration
  def self.up
    remove_column :service_providers, :is_default
  end

  def self.down
    add_column :service_providers, :is_default, :boolean, :default => false, :null => false
  end
end
