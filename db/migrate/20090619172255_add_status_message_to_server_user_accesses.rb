class AddStatusMessageToServerUserAccesses < ActiveRecord::Migration
  def self.up
    add_column :server_user_accesses, :status_message, :text
  end

  def self.down
    remove_column :server_user_accesses, :status_message
  end
end
