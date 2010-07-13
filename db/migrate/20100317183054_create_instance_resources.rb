class CreateInstanceResources < ActiveRecord::Migration
  def self.up
    create_table :instance_resources do |t|
      t.string :type
      t.integer :instance_id
      t.integer :cloud_resource_id
      t.string :state
      t.text :state_description
      t.boolean :force_allocation
      t.string :params

      t.timestamps
    end
    add_index :instance_resources, [ :instance_id, :type ]
    add_index :instance_resources, :cloud_resource_id
  end

  def self.down
    drop_table :instance_resources
  end
end
