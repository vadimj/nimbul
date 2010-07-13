class AddServerNameToInstances < ActiveRecord::Migration
  def self.up
	add_column :instances, :server_name, :string
	add_index :instances, :server_id
	add_index :instances, :server_name
	add_index :instances, :volume_name
  end

  def self.down
	remove_column :instances, :server_name
  end
end
