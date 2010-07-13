class CreateServerProfileUserAccesses < ActiveRecord::Migration
  def self.up
    create_table :server_profile_user_accesses do |t|
      t.integer :server_profile_id
      t.integer :user_id
      t.string :role, :default => 'reader'

      t.timestamps
    end
  end

  def self.down
    drop_table :server_profile_user_accesses
  end
end
