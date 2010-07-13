class ModifyProviderAccountsForNewMessageSubsystem < ActiveRecord::Migration
  def self.up
    remove_column :provider_accounts, :msg_server_uri rescue nil
    remove_column :provider_accounts, :in_queue
    remove_column :provider_accounts, :out_queue
    remove_column :provider_accounts, :msg_access_key
    remove_column :provider_accounts, :msg_secret_key
    remove_column :provider_accounts, :msg_account_id

    add_column :provider_accounts, :messaging_uri,      :string, :default => '',         :null => false
    add_column :provider_accounts, :messaging_username, :string, :default => '',         :null => false
    add_column :provider_accounts, :messaging_password, :string, :default => '',         :null => false
    add_column :provider_accounts, :messaging_startup,  :string, :default => 'startup',  :null => false
    add_column :provider_accounts, :messaging_shutdown, :string, :default => 'shutdown', :null => false
    add_column :provider_accounts, :messaging_info,     :string, :default => 'info',     :null => false
    add_column :provider_accounts, :messaging_request,  :string, :default => 'request',  :null => false
    add_column :provider_accounts, :messaging_control,  :string, :default => 'control',  :null => false
  end

  def self.down
    remove_column :provider_accounts, :messaging_uri
    remove_column :provider_accounts, :messaging_username
    remove_column :provider_accounts, :messaging_password
    remove_column :provider_accounts, :messaging_startup
    remove_column :provider_accounts, :messaging_shutdown
    remove_column :provider_accounts, :messaging_info
    remove_column :provider_accounts, :messaging_request
    remove_column :provider_accounts, :messaging_control

    add_column :provider_accounts, :in_queue,       :string, :default => '', :null => false
    add_column :provider_accounts, :out_queue,      :string, :default => '', :null => false
    add_column :provider_accounts, :msg_access_key, :string, :default => '', :null => false
    add_column :provider_accounts, :msg_secret_key, :string, :default => '', :null => false
    add_column :provider_accounts, :msg_account_id, :string, :default => '', :null => false
  end
end
