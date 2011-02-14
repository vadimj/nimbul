class RemovePublicKeyFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :public_key
  end

  def self.down
    add_column :users, :public_key, :text
  end
end
