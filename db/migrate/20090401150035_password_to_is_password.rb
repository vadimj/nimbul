class PasswordToIsPassword < ActiveRecord::Migration
  def self.up
	rename_column :provider_account_parameters, :password, :is_password
	rename_column :server_parameters, :password, :is_password
  end

  def self.down
	rename_column :provider_account_parameters, :is_password, :password
	rename_column :server_parameters, :is_password, :password
  end
end
