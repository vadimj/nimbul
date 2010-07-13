class AddProviderAccountsUsersTable < ActiveRecord::Migration
  def self.up
    # generate the join table
    create_table "provider_accounts_users", :id => false do |t|
      t.integer "provider_account_id", "user_id"
    end
    add_index "provider_accounts_users", "provider_account_id"
    add_index "provider_accounts_users", "user_id"
  end

  def self.down
    drop_table "provider_accounts_users"
  end
end
