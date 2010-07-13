class AddDnsNameToInstances < ActiveRecord::Migration
  def self.up
	add_column :instances, :dns_name, :string
	add_column :instances, :public_ip, :string
	add_index :instances, :dns_name
	add_index :instances, :public_ip
  end

  def self.down
	remove_column :instances, :dns_name
	remove_column :instances, :public_ip
  end
end
