class RenameUserDataToStartupScriptInServers < ActiveRecord::Migration
  def self.up
	rename_column :servers, :user_data, :startup_script
  end

  def self.down
	rename_column :servers, :startup_script, :user_data
  end
end
