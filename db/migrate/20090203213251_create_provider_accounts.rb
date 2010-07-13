class CreateProviderAccounts < ActiveRecord::Migration
  def self.up
    create_table :provider_accounts do |t|
      t.string :name
      t.string :description
      t.string :external_id
      t.string :aws_access_key
      t.string :aws_secret_key
      t.datetime :refresh_at
      t.datetime :refreshed_at

      t.timestamps
    end
  end

  def self.down
    drop_table :provider_accounts
  end
end
