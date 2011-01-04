class CreateServerCloudResourceAllocations < ActiveRecord::Migration
  def self.up
    create_table :server_cloud_resource_allocations do |t|
      t.string :type
      t.integer :server_id
      t.integer :cloud_resource_id
      t.string :binding_point
      t.text :binding_params
      t.boolean :force_allocation, :default => false

      t.timestamps
    end
    add_index :server_cloud_resource_allocations, [ :server_id, :type ], :name => 'index_server_id_type_on_scra'
    add_index :server_cloud_resource_allocations, [ :cloud_resource_id, :type ], :name => 'index_cloud_resource_id_type_on_scra'
  end

  def self.down
    drop_table :server_cloud_resource_allocations
  end
end
