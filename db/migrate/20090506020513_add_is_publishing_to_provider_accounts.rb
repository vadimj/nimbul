class AddIsPublishingToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :is_publishing, :boolean, :default => true
  end

  def self.down
    remove_column :provider_accounts, :is_publishing
  end
end
