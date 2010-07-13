class AddAccountIdAndMsgKeysToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :account_id, :string
    add_column :provider_accounts, :msg_access_key, :string
    add_column :provider_accounts, :msg_secret_key, :string
  end

  def self.down
    remove_column :provider_accounts, :account_id
    remove_column :provider_accounts, :msg_access_key
    remove_column :provider_accounts, :msg_secret_key
  end
end
