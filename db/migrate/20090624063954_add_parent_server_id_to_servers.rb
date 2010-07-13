class AddParentServerIdToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :parent_server_id, :integer
    add_column :servers, :volume_class, :string, :default => 'Volume'
  end

  def self.down
    remove_column :servers, :parent_server_id
    remove_column :servers, :volume_class
  end
end
