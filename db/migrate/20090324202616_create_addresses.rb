class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :public_ip
      t.string :instance_id

      t.timestamps
    end
    add_index :addresses, :name
    add_index :addresses, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :addresses
  end
end
