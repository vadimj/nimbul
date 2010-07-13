class CreateProviderAccountParameters < ActiveRecord::Migration
  def self.up
    create_table :provider_account_parameters do |t|
      t.integer :provider_account_id
      t.integer :position
      t.string :name
      t.text :value
      t.boolean :password

      t.timestamps
    end
    add_index :provider_account_parameters, :name
    add_index :provider_account_parameters, [ :provider_account_id, :name ], :unique => true,
        :name => "index_account_parameters_on_account_id_and_name"
  end

  def self.down
    drop_table :provider_account_parameters
  end
end
