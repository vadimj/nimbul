class AddClusterIdToInstancesAndServers < ActiveRecord::Migration
  def self.up
    add_column :instances, :cluster_id, :integer
    add_index :instances, :cluster_id
    add_column :servers, :cluster_id, :integer
    add_index :servers, :cluster_id
  end

  def self.down
    remove_column :instances, :cluster_id
    remove_column :servers, :cluster_id
  end
end
