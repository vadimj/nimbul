class CreateIamResources < ActiveRecord::Migration
  def self.up
    create_table :iam_resources do |t|
      t.integer :provider_account_id
      t.string :cloud_id
      t.string :name
      t.string :type
      t.string :resource_path

      t.timestamps
    end
    add_index :iam_resources, [ :provider_account_id, :type ]
    add_index :iam_resources, [ :provider_account_id, :cloud_id ], :unique => true
    add_index :iam_resources, [ :provider_account_id, :name ], :unique => true
    add_index :iam_resources, [ :provider_account_id, :resource_path ], :unique => true
  end

  def self.down
    drop_table :iam_resources
  end
end
