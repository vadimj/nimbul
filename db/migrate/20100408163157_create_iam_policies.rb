class CreateIamPolicies < ActiveRecord::Migration
  def self.up
    create_table :iam_policies do |t|
      t.integer :provider_account_id
      t.string :name
      t.text :description
      t.string :cloud_id
      t.string :version

      t.timestamps
    end
    add_index :iam_policies, [ :provider_account_id, :name ], :unique => true
    add_index :iam_policies, [ :provider_account_id, :cloud_id ], :unique => true
  end

  def self.down
    drop_table :iam_policies
  end
end
