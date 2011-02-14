class CreateUserKeys < ActiveRecord::Migration
  def self.up
    create_table :user_keys do |t|
      t.integer :user_id
      t.text :public_key
      t.string :hash_of_public_key
      
      t.timestamps
    end
  end

  def self.down
    drop_table :user_keys
  end
end
