class AddProviderAccountIdToServerProfiles < ActiveRecord::Migration
  def self.up
    add_column :server_profiles, :provider_account_id, :integer
    add_index :server_profiles, :provider_account_id
  end

  def self.down
    remove_column :server_profiles, :provider_account_id
  end
end
