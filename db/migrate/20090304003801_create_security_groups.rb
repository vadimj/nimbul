class CreateSecurityGroups < ActiveRecord::Migration
  def self.up
    create_table :security_groups do |t|
      t.integer :provider_account_id
      t.string :owner_id
      t.string :name
      t.string :description

      t.timestamps
    end
    add_index :security_groups, :name
    add_index :security_groups, [ :provider_account_id, :name ], :unique => true
  end

  def self.down
    drop_table :security_groups
  end
end
