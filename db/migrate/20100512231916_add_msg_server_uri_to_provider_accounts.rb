class AddMsgServerUriToProviderAccounts < ActiveRecord::Migration
  def self.up
    add_column :provider_accounts, :msg_server_uri, :string
  end

  def self.down
    remove_column :provider_accounts, :msg_server_uri
  end
end
