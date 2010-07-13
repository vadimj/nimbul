class RemoveAwsKeysFromProviderAccounts < ActiveRecord::Migration
  def self.up
    remove_column :provider_accounts, :aws_access_key
    remove_column :provider_accounts, :aws_secret_key
  end

  def self.down
    add_column :provider_accounts, :aws_access_key, :string
    add_column :provider_accounts, :aws_secret_key, :string
  end
end
