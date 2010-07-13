class CreateIamStatements < ActiveRecord::Migration
  def self.up
    create_table :iam_statements do |t|
      t.integer :iam_policy_id
      t.string :sid
      t.string :effect
      t.string :action
      t.string :not_action
      t.string :resource
      t.string :not_resource

      t.timestamps
    end
    add_index :iam_statements, [ :iam_policy_id, :sid ], :unique => true
  end

  def self.down
    drop_table :iam_statements
  end
end
