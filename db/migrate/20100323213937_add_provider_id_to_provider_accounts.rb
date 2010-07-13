class AddProviderIdToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :provider_id, :integer
    add_index :provider_accounts, [ :provider_id ]
  end

  def self.down
    remove_column :provider_accounts, :provider_id
  end
end
