class AddPrivateIpToInstance < ActiveRecord::Migration
  def self.up
    add_column :instances, :private_ip, :string
  end

  def self.down
    remove_column :instances, :private_ip
  end
end
