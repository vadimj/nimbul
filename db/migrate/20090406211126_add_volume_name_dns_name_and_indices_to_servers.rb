class AddVolumeNameDnsNameAndIndicesToServers < ActiveRecord::Migration
  def self.up
	add_column :servers, :volume_name, :string
	add_column :servers, :dns_name, :string
	add_index :servers, :volume_id
	add_index :servers, :volume_name
	add_index :servers, :public_ip
	add_index :servers, :dns_name
	add_index :servers, :key_name
  end

  def self.down
	remove_column :servers, :volume_name
	remove_column :servers, :dns_name
  end
end
