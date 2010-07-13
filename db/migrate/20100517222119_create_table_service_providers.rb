class CreateTableServiceProviders < ActiveRecord::Migration
  def self.up
    create_table :service_providers do |t|
      t.primary_key :id
      t.integer :service_type_id, :null => false
      t.integer :server_id, :null => false
      t.boolean :is_default, :default => false, :null => false
      t.timestamps
    end

    add_index :service_providers, :is_default
    add_index :service_providers, [:service_type_id, :server_id], :unique => true, :name => :idx_sp_service_type_server_id
  end

  def self.down
    drop_table :service_providers
  end
end
