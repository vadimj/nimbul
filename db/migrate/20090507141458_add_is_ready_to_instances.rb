class AddIsReadyToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :is_ready, :boolean, :default => false
  end

  def self.down
    remove_column :instances, :is_ready
  end
end
