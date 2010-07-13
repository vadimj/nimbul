class CreateClusterParameters < ActiveRecord::Migration
  def self.up
    create_table :cluster_parameters do |t|
      t.integer :cluster_id
      t.integer :position
      t.string :type
      t.string :name
      t.text :value
      t.boolean :is_protected, :default => false

      t.timestamps
    end
    add_index :cluster_parameters, [ :cluster_id, :name ], :unique => true
  end

  def self.down
    drop_table :cluster_parameters
  end
end
