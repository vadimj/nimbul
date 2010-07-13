class CreateCloudResources < ActiveRecord::Migration
  def self.up
    create_table :cloud_resources do |t|
      t.string :type
      t.integer :provider_account_id
      t.integer :zone_id
      t.string :cloud_id
      t.string :name
      t.string :state, :default => 'unknown'
      t.datetime :create_time
      t.datetime :update_time
      t.integer :size
      t.string :parent_cloud_id
      t.boolean :is_enabled, :default => true
      t.text :meta_data

      t.timestamps
    end
    add_index :cloud_resources, [ :provider_account_id, :type ]
    add_index :cloud_resources, [ :provider_account_id, :cloud_id ], :unique => true
    add_index :cloud_resources, :zone_id
    add_index :cloud_resources, [ :provider_account_id, :name ], :unique => true
    add_index :cloud_resources, [ :provider_account_id, :parent_cloud_id ]

  end

  def self.down
    drop_table :cloud_resources
  end
end
