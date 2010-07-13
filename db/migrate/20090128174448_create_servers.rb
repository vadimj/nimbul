class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :image_id
      t.string :type
      t.string :key_pair
      t.string :zone
      t.string :public_ip
      t.string :volume_id
      t.text :user_data
      t.string :state

      t.timestamps
    end
    add_index :servers, :name
    add_index :servers, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :servers
  end
end
