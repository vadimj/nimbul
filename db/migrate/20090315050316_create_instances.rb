class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table :instances do |t|
      t.string :instance_id
      t.integer :provider_account_id
      t.integer :server_id
      t.integer :server_pool_id
      t.string :image_id
      t.string :type
      t.string :key_name
      t.string :zone
      t.string :state
      t.string :public_dns
      t.string :private_dns
      t.datetime :launch_time
      t.string :ramdisk_id
      t.string :kernel_id
      t.string :reason
      t.string :product_codes
      t.integer :index

      t.timestamps
    end
    add_index :instances, :instance_id
    add_index :instances, :key_name
  end

  def self.down
    drop_table :instances
  end
end
