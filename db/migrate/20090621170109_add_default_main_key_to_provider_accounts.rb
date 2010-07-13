class AddDefaultMainKeyToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :default_main_key, :string
  end

  def self.down
    remove_column :provider_accounts, :default_main_key
  end
end
