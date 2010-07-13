class CreateProviderAccountsPublishers < ActiveRecord::Migration
  def self.up
    create_table "provider_accounts_publishers", :id => false do |t|
      t.integer "provider_account_id", "publisher_id"
    end
    add_index "provider_accounts_publishers", "provider_account_id"
    add_index "provider_accounts_publishers", "publisher_id"
  end

  def self.down
    drop_table "provider_accounts_publishers"
  end
end
