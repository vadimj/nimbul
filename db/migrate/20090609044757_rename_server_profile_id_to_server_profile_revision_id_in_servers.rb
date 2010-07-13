class RenameServerProfileIdToServerProfileRevisionIdInServers < ActiveRecord::Migration
  def self.up
    rename_column :servers, :server_profile_id, :server_profile_revision_id
  end

  def self.down
    rename_column :servers, :server_profile_revision_id, :server_profile_id
  end
end
