class CreateServerUserAccesses < ActiveRecord::Migration
  def self.up
    create_table :server_user_accesses do |t|
      t.integer :server_id
      t.integer :user_id
      t.string :server_user
      t.integer :schedule_id
      t.boolean :is_enabled

      t.timestamps
    end
	add_index :server_user_accesses, [ :server_id, :user_id , :server_user], :unique => true,
		:name => :index_user_accesses_on_server_user_server_user
	add_index :server_user_accesses, :user_id
	add_index :server_user_accesses, :server_user
	add_index :server_user_accesses, :schedule_id
  end

  def self.down
    drop_table :server_user_accesses
  end
end
