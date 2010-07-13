class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.integer :provider_account_id
      t.string :provider_account_name
      t.integer :security_group_id
      t.string :security_group_name
      t.integer :server_id
      t.string :server_name
      t.integer :user_id
      t.string :user_login
      t.string :subject
      t.string :action
      t.string :object
      t.string :description

      t.timestamps
    end
    add_index :events, :provider_account_id
    add_index :events, :provider_account_name
    add_index :events, :security_group_id
    add_index :events, :security_group_name
    add_index :events, :server_id
    add_index :events, :server_name
    add_index :events, :user_id
    add_index :events, :user_login
    add_index :events, :subject
    add_index :events, :action
    add_index :events, :object
    add_index :events, :description
  end

  def self.down
    drop_table :events
  end
end
