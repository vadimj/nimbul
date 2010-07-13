class CreateServerImages < ActiveRecord::Migration
  def self.up
    create_table :server_images do |t|
      t.string :image_id
      t.integer :provider_account_id
      t.string :name
      t.string :type
      t.string :kernel_id
      t.string :ramdisk_id
      t.string :owner_id
      t.boolean :is_public
      t.string :state
      t.string :location
      t.string :architecture
      t.string :server_image_type

      t.timestamps
    end
    add_index :server_images, :image_id
    add_index :server_images, :name
    add_index :server_images, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :server_images
  end
end
