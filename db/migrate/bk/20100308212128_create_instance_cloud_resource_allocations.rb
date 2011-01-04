class CreateInstanceCloudResourceAllocations < ActiveRecord::Migration
  def self.up
    create_table :instance_cloud_resource_allocations do |t|
      t.string :type
      t.integer :instance_id
      t.integer :cloud_resource_id
      t.string :binding_point
      t.text :binding_params
      t.string :state
      t.boolean :force_allocation

      t.timestamps
    end
    add_index :instance_cloud_resource_allocations, [ :instance_id, :type ], :name => 'index_instance_id_type_on_icra'
    add_index :instance_cloud_resource_allocations, [ :cloud_resource_id, :type ], :name => 'index_cloud_resource_id_type_on_icra'
  end

  def self.down
    drop_table :instance_cloud_resource_allocations
  end
end
