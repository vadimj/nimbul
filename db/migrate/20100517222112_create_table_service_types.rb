class CreateTableServiceTypes < ActiveRecord::Migration
  def self.up
    create_table :service_types do |t|
      t.primary_key :id
      t.string :name, :limit => 60, :null => false
      t.string :fqdn, :limit => 255, :null => false
      t.text   :description
      t.timestamps
    end

    add_index :service_types, :name, :unique => true
    add_index :service_types, :fqdn, :unique => true
  end

  def self.down
    drop_table :service_types
  end
end
