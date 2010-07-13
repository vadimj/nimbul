class AddOperationIdToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :operation_id, :integer
    add_index :messages, :operation_id 
  end

  def self.down
    remove_column :messages, :operation_id
  end
end
