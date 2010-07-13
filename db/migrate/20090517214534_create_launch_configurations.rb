class CreateLaunchConfigurations < ActiveRecord::Migration
  def self.up
    create_table :launch_configurations do |t|
      t.integer :provider_account_id
      t.integer :server_id
      t.string :name
      t.string :launch_configuration_name
      t.string :description
      t.string :instance_type
      t.string :image_id
      t.string :ramdisk_id
      t.string :kernel_id
      t.string :key_name
      t.text :user_data
      t.timestamp :created_time

      t.timestamps
    end
    add_index :launch_configurations, :provider_account_id
    add_index :launch_configurations, :server_id
    add_index :launch_configurations, :name
    add_index :launch_configurations, :launch_configuration_name
    add_index :launch_configurations, :image_id
	
	create_table :load_balancers do |t|
	  t.integer :launch_configuration_id
	  t.string :name
	  
	  t.timestamps
	end
	add_index :load_balancers, :launch_configuration_id

	create_table :launch_configurations_security_groups, :id => false do |t|
		t.integer :launch_configuration_id, :security_group_id
	end
	add_index :launch_configurations_security_groups, :launch_configuration_id, :name => :index_configurations_groups_on_configuration_id
	add_index :launch_configurations_security_groups, :security_group_id, :name => :index_configurations_groups_on_group_id
	
	create_table :block_device_mappings do |t|
	  t.integer :launch_configuration_id
	  t.string :virtual_name
	  t.string :device_name
	  
	  t.timestamps
	end
	add_index :block_device_mappings, :launch_configuration_id
  end

  def self.down
    drop_table :launch_configurations
	drop_table :launch_configurations_security_groups
	drop_table :block_device_mappings
  end
end
