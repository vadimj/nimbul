class RenameIsPasswordToIsProtectedInPap < ActiveRecord::Migration
  def self.up
    rename_column :provider_account_parameters, :is_password, :is_protected
  end

  def self.down
    rename_column :provider_account_parameters, :is_protected, :is_password
  end
end
