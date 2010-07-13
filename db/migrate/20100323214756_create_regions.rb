class CreateRegions < ActiveRecord::Migration
  def self.up
    create_table :regions do |t|
      t.integer :provider_id
      t.string :name
      t.text :description
      t.string :endpoint_url
      t.string :state
      t.text :meta_data

      t.timestamps
    end
    add_index :regions, [ :provider_id, :name ], :unique => true
    add_index :regions, :name
  end

  def self.down
    drop_table :regions
  end
end
