class AddPublishingParametersToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :last_published, :timestamp
    add_column :provider_accounts, :publish_at, :timestamp
    add_column :provider_accounts, :publish_every, :integer, :default => 60
	add_column :provider_accounts, :s3_bucket, :string
	add_column :provider_accounts, :s3_object, :string
  end

  def self.down
    remove_column :provider_accounts, :last_published
    remove_column :provider_accounts, :publish_at
    remove_column :provider_accounts, :publish_every
	remove_column :provider_accounts, :s3_bucket
	remove_column :provider_accounts, :s3_object
  end
end
