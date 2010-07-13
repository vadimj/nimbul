class AddServerProfileIdToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :server_profile_id, :integer
  end

  def self.down
    remove_column :servers, :server_profile_id
  end
end
