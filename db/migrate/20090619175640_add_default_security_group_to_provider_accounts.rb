class AddDefaultSecurityGroupToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :default_security_group, :string
  end

  def self.down
    remove_column :provider_accounts, :default_security_group
  end
end
