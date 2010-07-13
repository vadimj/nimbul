class CreateOperations < ActiveRecord::Migration
  def self.up
    create_table :operations do |t|
      t.integer :instance_id
      t.string :state, :default => 'proceed'
      t.string :type
      t.integer :current_step, :default => -1
      t.string :name
      t.text :args
      t.integer :attempts, :default => 0
      t.string :result_code
      t.text :result_message
      t.timestamps
    end
  end

  def self.down
    drop_table :operations
  end
end
