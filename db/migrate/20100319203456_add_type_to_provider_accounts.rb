class AddTypeToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :type, :string
    add_index :provider_accounts, [ :id, :type ]
  end

  def self.down
    remove_column :provider_accounts, :type
  end
end
