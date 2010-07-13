class RenameIsPasswordToIsProtectedInServers < ActiveRecord::Migration
  def self.up
    rename_column :server_parameters, :is_password, :is_protected
  end

  def self.down
    rename_column :server_parameters, :is_protected, :is_password
  end
end
