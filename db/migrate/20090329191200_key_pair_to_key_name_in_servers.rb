class KeyPairToKeyNameInServers < ActiveRecord::Migration
  def self.up
    rename_column :servers, :key_pair, :key_name
  end

  def self.down
    rename_column :servers, :key_name, :key_pair
  end
end
