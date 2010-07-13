class AddStartupScriptToProviderAccounts < ActiveRecord::Migration
  def self.up
	add_column :provider_accounts, :startup_script, :text
  end

  def self.down
	remove_column :provider_accounts, :startup_script
  end
end
