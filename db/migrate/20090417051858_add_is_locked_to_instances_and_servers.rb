class AddIsLockedToInstancesAndServers < ActiveRecord::Migration
  def self.up
    add_column :instances, :is_locked, :boolean
    add_column :instances, :device, :string, :default => '/dev/sdh'
    add_column :instances, :pending_volume_id, :string
    add_column :instances, :force_volume_id_allocation, :boolean
    add_column :instances, :pending_public_ip, :string
    add_column :instances, :force_public_ip_allocation, :boolean
    add_column :servers, :is_locked, :boolean
    add_column :servers, :device, :string, :default => '/dev/sdh'
  end

  def self.down
    remove_column :instances, :is_locked
    remove_column :instances, :device
    remove_column :instances, :pending_volume_id
    remove_column :instances, :force_volume_id_allocation
    remove_column :instances, :pending_public_ip
    remove_column :instances, :force_public_ip_allocation
    remove_column :servers, :is_locked
    remove_column :servers, :device
  end
end
