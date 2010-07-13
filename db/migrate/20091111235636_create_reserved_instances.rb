class CreateReservedInstances < ActiveRecord::Migration
  def self.up
    create_table :reserved_instances do |t|
      t.integer :provider_account_id
      t.string :reserved_instances_id
      t.string :instance_type
      t.string :zone
      t.datetime :start
      t.integer :duration
      t.float :usage_price
      t.float :fixed_price
      t.integer :count
      t.text :description
      t.string :state

      t.timestamps
    end
    add_index :reserved_instances, [ :provider_account_id, :reserved_instances_id ], :name => 'index_ri_id_on_reserved_instances'
    add_index :reserved_instances, [ :provider_account_id, :instance_type, :zone ], :name => 'index_type_zone_on_reserved_instances'
  end

  def self.down
    drop_table :reserved_instances
  end
end
