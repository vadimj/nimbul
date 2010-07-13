class AddInstanceTypeToServerProfileRevisions < ActiveRecord::Migration
  def self.up
    add_column :server_profile_revisions, :instance_type, :string, :default => 'm1.small'
  end

  def self.down
    remove_column :server_profile_revisions, :instance_type
  end
end
