class AddStatusMessageToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :status_message, :text
  end

  def self.down
    add_column :instances, :status_message
  end
end
