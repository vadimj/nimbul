class RenameTypeToInstanceTypeOnServers < ActiveRecord::Migration
  def self.up
    rename_column :instances, :type, :instance_type
  end

  def self.down
    rename_column :instances, :instance_type, :type
  end
end
