class CreateClustersUsers < ActiveRecord::Migration
  def self.up
    create_table :clusters_users, :id => false do |t|
      t.integer :cluster_id, :user_id
    end
    add_index :clusters_users, :cluster_id
    add_index :clusters_users, :user_id
  end

  def self.down
    drop_table :clusters_users
  end
end
