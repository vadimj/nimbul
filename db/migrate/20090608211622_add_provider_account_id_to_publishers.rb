class AddProviderAccountIdToPublishers < ActiveRecord::Migration
  def self.up
    add_column :publishers, :provider_account_id, :integer
  end

  def self.down
    remove_column :publishers, :provider_account_id
  end
end
