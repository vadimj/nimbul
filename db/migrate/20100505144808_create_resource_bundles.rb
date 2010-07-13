class CreateResourceBundles < ActiveRecord::Migration
  def self.up
    create_table :resource_bundles do |t|
      t.string :type
      t.integer :server_id
      t.integer :position
      t.integer :instance_id
      t.string :state

      t.timestamps
    end
    add_index :resource_bundles, :type
    add_index :resource_bundles, :server_id
    add_index :resource_bundles, :instance_id
  end

  def self.down
    drop_table :resource_bundles
  end
end
