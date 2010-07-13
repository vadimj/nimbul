class CreateIamConditions < ActiveRecord::Migration
  def self.up
    create_table :iam_conditions do |t|
      t.integer :iam_statement_id
      t.string :type
      t.string :operator
      t.string :name
      t.string :value

      t.timestamps
    end
    add_index :iam_conditions, [ :iam_statement_id, :type ]
    add_index :iam_conditions, [ :iam_statement_id, :name ]
  end

  def self.down
    drop_table :iam_conditions
  end
end
