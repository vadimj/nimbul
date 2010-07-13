class CreateProviders < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.string :name
      t.string :long_name
      t.text :description
      t.string :main_documentation_url
      t.string :api_documentation_url
      t.string :endpoint_url
      t.string :state
      t.string :adapter_class

      t.timestamps
    end
    add_index :providers, :name, :unique => true
  end

  def self.down
    drop_table :providers
  end
end
