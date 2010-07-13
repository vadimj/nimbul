class CreateServerParametersTable < ActiveRecord::Migration
  def self.up
    create_table :server_parameters do |t|
      t.integer :server_id
      t.integer :position
      t.string :name
      t.text :value
      t.boolean :password

      t.timestamps
    end
	add_index :server_parameters, :server_id
    add_index :server_parameters, [ :server_id, :name ], :unique => true
  end

  def self.down
    drop_table :server_parameters
  end
end
