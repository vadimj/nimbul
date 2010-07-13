class AddIndexesToUsers < ActiveRecord::Migration
  def self.up
    add_index :users, :name
    add_index :users, :email
  end

  def self.down
    remove_index :users, :name
    remove_index :users, :email
  end
end
