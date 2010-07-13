class CreateCloudResourcesClusters < ActiveRecord::Migration
  def self.up
    create_table :cloud_resources_clusters, :id => false do |t|
      t.integer :cloud_resource_id, :cluster_id
    end
    add_index :cloud_resources_clusters, :cloud_resource_id
    add_index :cloud_resources_clusters, :cluster_id
  end

  def self.down
    drop_table :cloud_resources_clusters
  end
end
