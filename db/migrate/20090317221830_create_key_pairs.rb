class CreateKeyPairs < ActiveRecord::Migration
  def self.up
    create_table :key_pairs do |t|
      t.integer :provider_account_id
      t.string :name
      t.string :fingerprint
      t.text :private_key
      t.text :public_key

      t.timestamps
    end
    add_index :key_pairs, :name
    add_index :key_pairs, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :key_pairs
  end
end
