class AddServerTaskIdToOperations < ActiveRecord::Migration
  def self.up
    add_column :operations, :server_task_id, :integer
  end

  def self.down
    remove_column :operations, :server_task_id
  end
end
