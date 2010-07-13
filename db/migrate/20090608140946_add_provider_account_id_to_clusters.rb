class AddProviderAccountIdToClusters < ActiveRecord::Migration
  def self.up
    add_column :clusters, :provider_account_id, :integer
    add_index :clusters, :provider_account_id
  end

  def self.down
    remove_column :clusters, :provider_account_id
  end
end
