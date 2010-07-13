class AddForceAllocationsToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :force_public_ip_allocation, :boolean, :default => false
    add_column :servers, :force_volume_id_allocation, :boolean, :default => false
  end

  def self.down
    remove_column :servers, :force_public_ip_allocation
    remove_column :servers, :force_volume_id_allocation
  end
end
