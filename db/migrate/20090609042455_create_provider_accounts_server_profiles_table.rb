class CreateProviderAccountsServerProfilesTable < ActiveRecord::Migration
  def self.up
    create_table :provider_accounts_server_profiles, :id => false do |t|
      t.integer :provider_account_id, :server_profile_id
    end
    add_index :provider_accounts_server_profiles, :provider_account_id
    add_index :provider_accounts_server_profiles, :server_profile_id
  end

  def self.down
    drop_table :provider_accounts_server_profiles
  end
end
