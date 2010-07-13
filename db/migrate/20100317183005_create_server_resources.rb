class CreateServerResources < ActiveRecord::Migration
  def self.up
    create_table :server_resources do |t|
      t.string :type
      t.integer :server_id
      t.integer :cloud_resource_id
      t.string :description
      t.boolean :force_allocation
      t.string :params

      t.timestamps
    end
    add_index :server_resources, [ :server_id, :type ]
    add_index :server_resources, :cloud_resource_id
  end

  def self.down
    drop_table :server_resources
  end
end
