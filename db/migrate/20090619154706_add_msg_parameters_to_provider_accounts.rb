class AddMsgParametersToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :msg_account_id, :string
    add_column :provider_accounts, :auto_lock_instances, :boolean, :default => false
  end

  def self.down
    remove_column :provider_accounts, :msg_account_id
    remove_column :provider_accounts, :auto_lock_instances
  end
end
